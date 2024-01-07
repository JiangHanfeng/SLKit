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
    private var device: SLDevice? {
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
                SLLog.debug("ip/ble/连接状态发生变化")
                if connected {
//                    self?.stopListenPort()
                    SLLog.debug("已连接到设备，准备停止广播")
                    self?.stopAdvertising()
                    guard let self, let device = self.device else {
                        SLLog.debug("主页或已连接设备不存在")
                        return
                    }
                    device.localClient.unexpectedDisconnectHandler = { [weak weakSelf = self] error in
                        weakSelf?.device = nil
                        weakSelf?.toast("已断开连接")
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
                            self?.stopListenPort()
                            self?.stopAdvertising()
                            self?.ipv4 = ip
                            let serverPort = UInt16.random(in: 10000..<65535)
                            SLLog.debug("准备重新监听本地端口\(serverPort)")
                            self?.startListenPort(serverPort, success: {
                                if bleAvailable {
                                    if let advertiseError = self?.startAdvertising(port: serverPort) {
                                        SLLog.debug("广播错误:\(advertiseError)")
                                        self?.toast(advertiseError)
                                    }
                                } else {
                                    SLLog.debug("ble状态不可用，暂不广播")
                                }
                            })
                        } else if let server = self?.localServer {
                            SLLog.debug("本机ip未发生变化，本地端口\(server.port)已监听，无需重新监听，准备重新广播")
                            if bleAvailable {
                                if let advertiseError = self?.startAdvertising(port: server.port) {
                                    SLLog.debug("广播错误:\(advertiseError)")
                                    self?.toast(advertiseError)
                                }
                            } else {
                                SLLog.debug("ble状态不可用，暂不广播")
                            }
                        } else {
                            let serverPort = UInt16.random(in: 10000..<65535)
                            SLLog.debug("本机ip未发生变化，本地端口\(serverPort)未监听，需开启监听并发起广播")
                            self?.startListenPort(serverPort, success: {
                                if bleAvailable {
                                    if let advertiseError = self?.startAdvertising(port: serverPort) {
                                        SLLog.debug("广播错误:\(advertiseError)")
                                        self?.toast(advertiseError)
                                    }
                                } else {
                                    SLLog.debug("ble状态不可用，暂不广播")
                                }
                            })
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @IBAction private func onFileTransfer() {
        navigationController?.show(SCLFileHistoryViewController(), sender: nil)
    }
    
    @IBAction private func onSetting() {
        navigationController?.show(SCLSettingViewController(), sender: nil)
    }
    
    private func getConnectionVc() -> SCLConnectionViewController {
        if connectionVc == nil {
            connectionVc = SCLConnectionViewController { [weak self] device in
                self?.device = device
            }
        }
        return connectionVc!
    }
    
    private func getDeviceVc(_ device: SLDevice) -> SCLDeviceViewController {
        return SCLDeviceViewController(device: device) { [weak self] in
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
        if transferringCount == 0 && !transferringCountLabel.isHidden {
            transferringCountLabel.alpha = 1
            UIView.animate(withDuration: 0.25) {
                self.transferringCountLabel.alpha = 0
            } completion: { _ in
                self.transferringCountLabel.isHidden = true
            }

        } else if transferringCountLabel.isHidden {
            transferringCountLabel.alpha = 0
            transferringCountLabel.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.transferringCountLabel.alpha = 1
            }
        }
    }
    
    private func updateReceivingFiles() {
        guard let fileVc = UIApplication.shared.currentController() as? SCLFileHistoryViewController else {
            return
        }
        let receivingModels = SLTransferManager.share().currentReceiveFileTransfer().filter { item in
            !item.files.isEmpty
        }.map { item in
            return SCLTransferringModel(taskId: item.taskId, type: .receive, name: item.files.first!.name, count: item.files.count, progress: item.currentProgress)
        }
        fileVc.updateReceivingFileModels(receivingModels)
    }
    
    private func updateSendingFiels() {
        guard let fileVc = UIApplication.shared.currentController() as? SCLFileHistoryViewController else {
            return
        }
        if let sendFile = SLTransferManager.share().currentSendFileTransfer(), !sendFile.files.isEmpty {
            let sendModel = SCLTransferringModel(taskId: sendFile.taskId, type: .send, name: sendFile.files.first!.name, count: sendFile.files.count, progress: sendFile.currentProgress)
            fileVc.updateSendingFileModels([sendModel])
        } else {
            fileVc.updateSendingFileModels([])
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
    func startListenPort(_ port: UInt16, success: () -> Void) {
        SLSocketManager.shared.startListen(port: port, gateway: SLSocketServerGateway(connectionAuthrizationHandler: { socket, acceptedCount in
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
            case .failure(_):
                print("监听本地端口:\(port)失败")
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
        guard let macBytes = SCLUtil.getDeviceMac().macBytes() else {
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
        } catch let e {
            return e.localizedDescription
        }
        return nil
    }
    
    func stopAdvertising() {
        SLPeripheralManager.shared.stopAdvertising()
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
        
        SLTransferManager.share().cancelReceiveFileBlock = {[weak self] _,taskId,_ in
            SLLog.debug("SLTransferManager.share().cancelReceiveFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateReceivingFiles()
        }
        
        SLTransferManager.share().completeReceiveFileBlock = {[weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().completeReceiveFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateReceivingFiles()
        }
        
        SLTransferManager.share().receiveFileFailBlock = {[weak self] _,taskId,_ in
            SLLog.debug("SLTransferManager.share().receiveFileFailBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateReceivingFiles()
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
        }
        
        SLTransferManager.share().completeSendFileBlock = { [weak self] _,taskId in
            SLLog.debug("SLTransferManager.share().completeSendFileBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
        }
        
        SLTransferManager.share().sendFileFailBlock = { [weak self] _,taskId,_ in
            SLLog.debug("SLTransferManager.share().sendFileFailBlock executed with taskId:\(taskId)")
            self?.updateTransferringFilesCount()
            self?.updateSendingFiels()
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
    
    func test() {
        let connect = Observable.create { subscriber in
            Task {
                do {
                    let sock = try await SLSocketManager.shared.connect(host: "192.168.3.170", port: 8088)
                    subscriber.onNext(sock)
                    subscriber.onCompleted()
                } catch let e {
                    subscriber.onError(e)
                }
            }
            return Disposables.create()
        }
        // MARK: 测试：并发100个请求
        let concurrencyRequests: ((_ sock: SLSocketClient) -> Observable) = { sock in
            return Observable.create { subscriber in
                for _ in 0..<100 {
                    DispatchQueue.global().async {
                        Task {
                            do {
                                let response = try await SLSocketManager.shared.send(SCLSocketRequest(content: SCLSocketGenericContent(cmd: .login)), from: sock, for: SCLSocketResponse<SCLSocketGenericContent>.self)
                            } catch _ {}
                        }
                    }
                }
                subscriber.onNext(Void())
                subscriber.onCompleted()
                return Disposables.create()
            }
        }
        connect.flatMap { sock in
            print("socket连接成功")
            return concurrencyRequests(sock)
        }.subscribe (onNext: {
    
        }, onError: { _ in
            
        }, onCompleted: {
            
        }).disposed(by: disposeBag)
    }
}
