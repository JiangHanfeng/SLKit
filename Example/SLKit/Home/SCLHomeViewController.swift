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
    private var device: SLDevice? {
        didSet {
            if device != oldValue {
                deviceUpdatedHandler?(device)
            }
        }
    }
    
    public var deviceUpdatedHandler: ((SLDevice?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: true)
        transitionToChild(getConnectionVc()) { childView in
            childView.snp.makeConstraints { make in
                make.top.equalTo(self.topBar.snp.bottom)
                make.left.right.equalTo(0)
                make.bottom.equalTo(-UIDevice.safeDistanceBottom())
            }
        }
        
        let ipSignal = Observable.create { observer in
            SLNetworkManager.shared.startMonitorWifi()
            SLNetworkManager.shared.ipv4OfWifiUpdated = { ip in
                observer.onNext(ip ?? "")
            }
            return Disposables.create()
        }
        let bleStateSignal = Observable.create { observer in
            observer.onNext(SLCentralManager.shared.state == .poweredOn)
            SLCentralManager.shared.stateUpdateHandler = SLBleStateUpdatedHandler(handle: { state in
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
            .subscribe(onNext: { [weak self] (ip, bleAvailable, connected) in
                if connected {
                    // TODO: 停止广播
                    
                    guard let self, let device = self.device else {
                        return
                    }
                    switch device.role {
                    case .client(_, _):
                        break
                    case .server(let sLSocketClient):
                        sLSocketClient.unexpectedDisconnectHandler = { [weak weakSelf = self] error in
                            weakSelf?.device = nil
                            weakSelf?.toast("已断开连接")
                        }
                    }
                    self.transitionToChild(self.getDeviceVc(device)) { childView in
                        childView.snp.makeConstraints { make in
                            make.top.equalTo(self.topBar.snp.bottom)
                            make.left.right.equalTo(0)
                            make.bottom.equalTo(-UIDevice.safeDistanceBottom())
                        }
                    }
                } else {
                    if ip.isEmpty {
                        self?.stopListenPort()
                    } else {
                        self?.startListenPort()
                    }
                    if bleAvailable {
                        // TODO: 广播
                    } else {
                        // TODO: 停止广播
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
        return SCLConnectionViewController { [weak self] device in
            self?.device = device
        }
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

    func startListenPort() {
        SLSocketManager.shared.startListen(port: 8099, gateway: SLSocketServerGateway(connectionAuthrizationHandler: { socket, acceptedCount in
            return .access(nil)
        }, dataAuthrizationHandler: { [weak self] socket, data in
            if self?.device == nil {
                // TODO: 解析data，赋值device
                return .access(nil)
            }
            return .deny("已与其它客户端进行连接".data(using: .utf8))
        })) { result in
            switch result {
            case .success(_):
                print("socket server已启动")
            case .failure(_):
                print("socket server启动失败")
            }
        }
    }
    
    func stopListenPort() {
        SLSocketManager.shared.stopListen(port: 8099) {
            
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
