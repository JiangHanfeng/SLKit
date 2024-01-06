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
    private var ipv4: String?
    private var localServer: SLSocketServer?
    private var device: SLDevice? {
        didSet {
            if device != oldValue {
                deviceUpdatedHandler?(device)
            }
        }
    }
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
                        self?.ipv4 = nil
                        self?.stopListenPort()
                        self?.stopAdvertising()
                    } else {
                        self?.stopAdvertising()
                        if self?.ipv4 != ip {
                            self?.stopListenPort()
                            self?.ipv4 = ip
                            let serverPort = UInt16.random(in: 10000..<65535)
                            self?.startListenPort(serverPort, success: {
                                if bleAvailable {
                                    if let advertiseError = self?.startAdvertising(port: serverPort) {
                                        self?.toast(advertiseError)
                                    }
                                }
                            })
                        } else if let server = self?.localServer {
                            if bleAvailable {
                                if let advertiseError = self?.startAdvertising(port: server.port) {
                                    self?.toast(advertiseError)
                                }
                            }
                        } else {
                            let serverPort = UInt16.random(in: 10000..<65535)
                            self?.startListenPort(serverPort, success: {
                                if bleAvailable {
                                    if let advertiseError = self?.startAdvertising(port: serverPort) {
                                        self?.toast(advertiseError)
                                    }
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
