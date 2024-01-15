//
//  SCLHomeViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import SLKit
import CoreBluetooth

class SCLHomeViewController: SCLBaseViewController {
    
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var transferringCountLabel: UILabel!
    private var ipv4: String?
    private var localServer: SLSocketServer?
    var device: SLDevice? {
        didSet {
            if device != oldValue {
                deviceUpdatedHandler?(device)
            }
        }
    }
    private var transferringFileModels: [SLFileTransferModel] = []
    private var connectionVc: SCLConnectionViewController?
    
    public var deviceUpdatedHandler: ((SLDevice?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: true)
        let ipSignal = Observable.create { observer in
            SLNetworkManager.shared.startMonitorWifi()
            SLNetworkManager.shared.ipv4OfWifiUpdated = { ip in
                observer.onNext(ip ?? "")
            }
            return Disposables.create()
        }
        let bleStateSignal = Observable.create { observer in
            observer.onNext(SLCentralManager.shared.state == .poweredOn)
            SLPeripheralManager.shared.stateUpdatedHandler = SLBleStateUpdatedHandler(handle: { state in
                observer.onNext(state == .poweredOn)
            })
            return Disposables.create()
        }
        let deviceSignal = Observable.create { [weak self] observer in
            if let self {
                self.deviceUpdatedHandler = { device in
                    observer.onNext(device != nil)
                }
            } else {
                observer.onCompleted()
            }
            return Disposables.create()
        }
        Observable.combineLatest(ipSignal, bleStateSignal, deviceSignal)
            .observe(on: MainScheduler()).subscribe(onNext: { [weak self] (ip, bleAvailable, connected) in
                SLLog.debug("ip/ble/设备状态发生变化:\n当前ip:\(ip)，蓝牙开关：\(bleAvailable ? "开" : "关")，设备状态：\(connected ? "已连接" : "未连接")")
                if connected {
                    SLLog.debug("已连接到设备，准备停止广播")
                    self?.stopListenPort()
                    self?.stopAdvertising()
                    guard let self, let device = self.device else {
                        SLLog.debug("主页或已连接设备不存在")
                        return
                    }
                    device.localClient.unexpectedDisconnectHandler = { [weak weakSelf = self] error in
                        weakSelf?.tryReconnect()
                    }
                    self.transitionToChild(self.getDeviceVc(device)) {
                        childView in
                        SLLog.debug("跳转至设备页")
                        childView.snp.makeConstraints { make in
                            make.top.equalTo(self.topBar.snp.bottom)
                            make.left.right.equalTo(0)
                            make.bottom.equalTo(-UIDevice.safeDistanceBottom())
                        }
                    }
                } else {
                    if let _ = self?.presentedViewController {
                        self?.dismiss(animated: true, completion: nil)
                    }
                    if ip.isEmpty {
                        SLLog.debug("本机ip为空，准备停止监听本地端口（若已启用）并停止广播")
                        self?.ipv4 = nil
                        self?.stopListenPort()
                        self?.stopAdvertising()
                    } else {
                        if self?.ipv4 != ip {
                            SLLog.debug("本机ip更新为\(ip)，准备停止监听本地端口并停止广播")
                            self?.ipv4 = ip
                            self?.stopListenPortAndAdervertising()
                            self?.startListenPortAndAdervertising()
                        } else if let server = self?.localServer {
                            SLLog.debug("本机ip未发生变化，本地端口\(server.port)已监听，无需重新监听，准备重新广播")
                            if let error = self?.startAdvertising(port: server.port) {
                                SLLog.debug("广播失败:\(error)")
                            }
                        } else {
                            SLLog.debug("本机ip未发生变化，本地端口未监听，需开启监听并发起广播")
                            self?.startListenPortAndAdervertising()
                        }
                    }
                    guard let self else {
                        return
                    }
                    self.transitionToChild(self.getConnectionVc()) { childView in
                        childView.snp.makeConstraints { make in
                            make.top.equalTo(self.topBar.snp.bottom)
                            make.left.right.equalTo(0)
                            make.bottom.equalTo(-UIDevice.safeDistanceBottom())
                        }
                    }
                }
            }, onError: { error in
                
            }, onCompleted: {
                
            }).disposed(by: disposeBag)
        deviceUpdatedHandler?(nil)
        configFileTransfer()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: enterForegroundNoti, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: enterBackgroundNoti, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    deinit {
        print("\(self) deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction private func onFileTransfer() {
        navigationController?.show(SCLFileHistoryViewController(), sender: nil)
    }
    
    @IBAction private func onSetting() {
        navigationController?.show(SCLSettingViewController(), sender: nil)
    }
    
    private func getConnectionVc() -> SCLConnectionViewController {
        if connectionVc == nil {
            connectionVc = SCLConnectionViewController(didStartScan: { [weak self] in
                SLLog.debug("开始扫描二维码")
                self?.stopAdvertising()
                self?.stopListenPort()
            }, didStopScan: { [weak self] scanSuccess in
                if !scanSuccess {
                    SLLog.debug("取消扫码或扫码识别失败")
                    self?.startListenPortAndAdervertising()
                }
            }, connectionCompletion: { [weak self] device in
                let isReconnect = self?.device != nil
                let connectSuccess = device != nil
                SLLog.debug("\(isReconnect ? "重连" : "连接")\(connectSuccess ? "成功" : "失败或取消")")
                self?.device = device
            })
        }
        return connectionVc!
    }
    
    private func getDeviceVc(_ device: SLDevice) -> SCLDeviceViewController {
        return SCLDeviceViewController(device: device) { [weak self] isInitiative in
            self?.device = nil
        }
    }
    
    private func tryReconnect() {
        if let device {
            let connectionVc = getConnectionVc()
            transitionToChild(connectionVc) { childView in
                childView.snp.makeConstraints { make in
                    make.top.equalTo(self.topBar.snp.bottom)
                    make.left.right.equalTo(0)
                    make.bottom.equalTo(-UIDevice.safeDistanceBottom())
                }
            } completion: {
                connectionVc.startConnect(host: device.localClient.host, port: device.localClient.port, mac: device.mac, name: device.name, isReconnect: true)
            }
        } else {
            toast("已断开连接")
        }
    }
    
    private func updateTransferringFilesCount() {
        let currentSendFileTransfer = SLTransferManager.share().currentSendFileTransfer()
        let sendingFilesCount = currentSendFileTransfer?.files.count ?? 0
        
        let currentReceiveFileTransfers = SLTransferManager.share().currentReceiveFileTransfer()
        let receivingFilesCount = currentReceiveFileTransfers.map { item in
            item.files.count
        }.reduce(0) { partialResult, i in
            partialResult + i
        }
        let transferringCount = sendingFilesCount + receivingFilesCount
        SLLog.debug("发送文件个数：\(sendingFilesCount), 接收文件个数： \(receivingFilesCount)，总共：\(transferringCount)")
        transferringCountLabel.text = "\(transferringCount)"
        if transferringCount == 0 {
            transferringCountLabel.alpha = 1
            UIView.animate(withDuration: 0.25) {
                self.transferringCountLabel.alpha = 0
            } completion: { _ in
                self.transferringCountLabel.isHidden = true
            }
            for child in children {
                if child.isKind(of: SCLDeviceViewController.self) {
                    (child as! SCLDeviceViewController).switchSendable(true)
                    break
                }
            }
        } else if transferringCountLabel.isHidden {
            transferringCountLabel.alpha = 0
            transferringCountLabel.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.transferringCountLabel.alpha = 1
            }
            for child in children {
                if child.isKind(of: SCLDeviceViewController.self) {
                    (child as! SCLDeviceViewController).switchSendable(false)
                    break
                }
            }
        }
    }
    
    private func updateReceivingFiles() {
        guard let fileVc = UIApplication.shared.currentController() as? SCLFileHistoryViewController else {
            return
        }
        DispatchQueue.main.async {
            fileVc.updateReceivingFiles()
        }
    }
    
    private func updateReceivedFiles() {
        guard let fileVc = UIApplication.shared.currentController() as? SCLFileHistoryViewController else {
            return
        }
        DispatchQueue.main.async {
            fileVc.updateFileRecords(type: .receive)
        }
    }
    
    private func updateSendingFiels() {
//        guard let fileVc = UIApplication.shared.currentController() as? SCLFileHistoryViewController else {
//            return
//        }
//        fileVc.updateSendingFiles()
        let deviceVc = children.first { item in
            item.isKind(of: SCLDeviceViewController.self)
        } as? SCLDeviceViewController
        if let sendFile = SLTransferManager.share().currentSendFileTransfer(), !sendFile.files.isEmpty {
            let sendModel = SCLTransferringModel(taskId: sendFile.taskId, type: .send, fileType: SCLFileTypeMapper[sendFile.files.first!.fileType()] ?? .unknown, name: sendFile.files.first!.name, count: sendFile.files.count, progress: sendFile.currentProgress, status: "%\(Int(sendFile.currentProgress * 100))")
            DispatchQueue.main.async {
                deviceVc?.updateSendingProgress(sendFile.currentProgress, taskId: sendFile.taskId)
            }
        } else {
            DispatchQueue.main.async {
                deviceVc?.hideSendingView()
            }
        }
    }
}

extension SCLHomeViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController.isEqual(self) {
            var vcs = navigationController.viewControllers
            while vcs.count > 1 {
                vcs.removeFirst()
            }
            navigationController.viewControllers = vcs
        }
    }
}

extension SCLHomeViewController {
    @objc func willEnterForeground() {
        if let _ = device {
        } else {
            startListenPortAndAdervertising()
        }
    }
    
    @objc func didEnterBackground() {
        stopListenPortAndAdervertising()
    }
    
    func startListenPort(success: @escaping (_ port: UInt16) -> Void, failure: @escaping (_ error: Error) -> Void) {
        let randomPort = UInt16.random(in: 10000..<65535)
        SLSocketManager.shared.startListen(port: randomPort, gateway: SLSocketServerGateway(connectionAuthrizationHandler: { socket, acceptedCount in
            return .access(nil)
        }, dataAuthrizationHandler: { [weak self] socket, data in
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
                    return .access(nil)
                }
                guard
                    let cmd = json["cmd"] as? Int,
                    let ip = json["ip"] as? String,
                    let _ = ip.ipV4Bytes(),
                    let port = json["port"] as? UInt16,
                    port > 0
                else {
                    return .access(nil)
                }
                let shouldConnect = self?.device == nil
                SLLog.debug("\(shouldConnect ? "需要" : "不需要")连接server:\(ip):\(port)")
                let resp = [
                    "cmd":cmd,
                    "state":shouldConnect ? 1 : 0
                ]
                if shouldConnect {
                    DispatchQueue.main.async {
                        self?.getConnectionVc().startConnect(host: ip, port: port, mac: "", name: "")
                    }
                }
                let respData = try? JSONSerialization.data(withJSONObject: resp)
                return .access(respData)
            } catch _ {
                return .deny("消息格式错误".data(using: .utf8))
            }
        })) { [weak self] result in
            switch result {
            case .success(let server):
                print("监听本地端口:\(server.port)成功")
                self?.localServer = server
                success(server.port)
            case .failure(let e):
                print("监听本地端口:\(randomPort)失败")
                failure(e)
            }
        }
    }
    
    func stopListenPort() {
        if let localServer {
            SLSocketManager.shared.stopListen(localServer) {
                SLLog.debug("已停止监听本地端口\(localServer.port)")
            }
            self.localServer = nil
        }
    }
    
    func startAdvertising(port: UInt16) -> String? {
        guard SLPeripheralManager.shared.available() else {
            return "蓝牙未开启或未授权"
        }
        guard let macBytes = SCLUtil.getTempMac().macBytes() else {
            return "无法获取mac"
        }
        let macData = Data(bytes: macBytes)
        
        guard let ipBytes = ipv4?.ipV4Bytes() else {
            return "无法获取ip"
        }
        let ipData = Data(bytes: ipBytes)

        var uint16 = CFSwapInt16BigToHost(port)
        let portBytes = withUnsafeBytes(of: &uint16) { Array($0) }
        let portData = Data(bytes: portBytes)
        
        let ipHeadBytes: [UInt8] = [0xdd, 0xe7]
        
        var ipPageData = Data()
        ipPageData.append(Data(bytes: ipHeadBytes))
        ipPageData.append(macData)
        ipPageData.append(ipData)
        ipPageData.append(portData)
        while ipPageData.count < 21 {
            ipPageData.append(Data(bytes: [0x00]))
        }
        stopAdvertising()
        do {
            try  SLPeripheralManager.shared.startAdvertising(["kCBAdvDataAppleBeaconKey":ipPageData])
            SLLog.debug("广播数据(deviveId:\(SCLUtil.getTempMac()),ip:\(ipv4 ?? ""),port:\(port))")
        } catch let e {
            return e.localizedDescription
        }
        return nil
    }
    
    func stopAdvertising() {
        SLPeripheralManager.shared.stopAdvertising()
    }
    
    func startListenPortAndAdervertising() {
        startListenPort { port in
            SLLog.debug("已监听端口\(port)")
            if let error = self.startAdvertising(port: port) {
                SLLog.debug("广播失败:\(error)")
            }
        } failure: { error in
            SLLog.debug("监听端口失败:\(error.localizedDescription)")
        }
    }
    
    func stopListenPortAndAdervertising() {
        stopAdvertising()
        stopListenPort()
    }
    
    func configFileTransfer(){
        SLTransferManager.share().config(withDeviceId: SCLUtil.getTempMac().split(separator: ":").joined(),
                                         deviceName: SCLUtil.getDeviceName())
        
        SLTransferManager.share().receiveFileRequestBlock = { [weak self] _,taskId,files in
            SLLog.debug("收到接收文件请求，接收个数：\(files.count)个，taskId：\(taskId)")
            guard let self else {
                SLLog.debug("但HomeViewController已被释放")
                return
            }
            self.present(FileDecisionViewController(deviceName: self.device?.name ?? "", filesCount: files.count, onRefused: {
                SLTransferManager.share().respondReceiveFiles(withTaskId: taskId, files:files, accept: false)
            }, onReceive: {
                SLTransferManager.share().respondReceiveFiles(withTaskId: taskId, files:files, accept: true)
            }), animated: true)
        }
        
        SLTransferManager.share().startReceiveFileBlock = { [weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().startReceiveFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateReceivingFiles()
        }
        
        SLTransferManager.share().receiveFileProgressBlock = {[weak self] _,taskId,progress in
            SLLog.debug("SLTransferManager.share().receiveFileProgressBlock executed with taskId:\(taskId),progress:\(progress)")
            if progress == 0 || progress >= 1 {
                self?.updateTransferringFilesCount()
            }
            self?.updateReceivingFiles()
        }
        
        SLTransferManager.share().cancelReceiveFileBlock = {[weak self] _,taskId, isInitiative in
            SLLog.debug("SLTransferManager.share().cancelReceiveFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateReceivingFiles()
            if !isInitiative, let vc = UIApplication.shared.currentController() as? FileDecisionViewController {
                vc.presentingViewController?.dismiss(animated: true)
                self?.toast("对方已取消发送文件")
            }
        }
        
        SLTransferManager.share().completeReceiveFileBlock = {[weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().completeReceiveFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateReceivingFiles()
            self?.toast("文件接收完成")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self?.updateReceivedFiles()
            })
        }
        
        SLTransferManager.share().receiveFileFailBlock = {[weak self] _,taskId,_ in
            SLLog.debug("SLTransferManager.share().receiveFileFailBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateReceivingFiles()
            self?.toast("文件接收失败")
        }
        
        SLTransferManager.share().nonReceiveFileBlock = {[weak self] _ in
            SLLog.debug("SLTransferManager.share().nonReceiveFileBlock executed")
            self?.updateTransferringFilesCount()
            self?.updateReceivingFiles()
        }
           
        SLTransferManager.share().waitSendFileBlock = { [weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().waitSendFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
        }
        
        // MARK: 1.开始发送文件
        SLTransferManager.share().startSendFileBlock = {[weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().startSendFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
            DispatchQueue.main.async {
                let deviceVc = self?.children.first { item in
                    item.isKind(of: SCLDeviceViewController.self)
                } as? SCLDeviceViewController
                deviceVc?.showSendingView()
            }
        }
        
        SLTransferManager.share().sendFileProgressBlock = { [weak self] _,taskId,progress in
            SLLog.debug("SLTransferManager.share().sendFileProgressBlock executed with taskId:\(taskId), progress:\(progress)")
            if progress == 0 || progress >= 1 {
                self?.updateTransferringFilesCount()
            }
            self?.updateSendingFiels()
        }
        
        SLTransferManager.share().refuseSendFileBlock = { [weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().refuseSendFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
        }
        
        SLTransferManager.share().cancelSendFileBlock = { [weak self] _,taskId,initiative in
                        SLLog.debug("SLTransferManager.share().cancelSendFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
            self?.toast("已取消发送文件")
        }
        
        SLTransferManager.share().completeSendFileBlock = { [weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().completeSendFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
            self?.toast("文件发送已完成")
        }
        
        SLTransferManager.share().sendFileFailBlock = { [weak self] _,taskId,_ in
            SLLog.debug("SLTransferManager.share().sendFileFailBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
            self?.toast("文件发送失败")
        }
    
        SLTransferManager.share().nonSendFileBlock = { [weak self] _ in
            SLLog.debug("SLTransferManager.share().nonSendFileBlock")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
        }

        SLTransferManager.share().upDateSendFileBlock = { [weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().upDateSendFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
        }
    }
}
