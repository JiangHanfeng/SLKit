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

class SCLHomeViewController: SCLBaseViewController {
    
    @IBOutlet weak var topBar: UIView!
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction private func onFileTransfer() {
        navigationController?.show(SCLFileHistoryViewController(), sender: nil)
    }
    
    @IBAction private func onSetting() {
        navigationController?.show(SCLSettingViewController(), sender: nil)
    }
    
    private func getConnectionVc() -> SCLConnectionViewController {
        return SCLConnectionViewController { [weak self] (socket, mac, name) in
            guard let self else {
                return
            }
            self.transitionToChild(self.getDeviceVc(socket, mac, name)) { childView in
                childView.snp.makeConstraints { make in
                    make.top.equalTo(self.topBar.snp.bottom)
                    make.left.right.equalTo(0)
                    make.bottom.equalTo(-UIDevice.safeDistanceBottom())
                }
            }
        }
    }
    
    private func getDeviceVc(_ sock: SLSocketClient, _ mac: String, _ name: String) -> SCLDeviceViewController {
        return SCLDeviceViewController(socket: sock, mac: mac, name: name) { [weak self] in
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
        // 并发100个请求
        let concurrencyRequests: ((_ sock: SLSocketClient) -> Observable) = { sock in
            return Observable.create { subscriber in
                for i in 0..<100 {
                    DispatchQueue.global().async {
                        Task {
                            do {
                                let response = try await SLSocketManager.shared.send(SCLTCPSocketRequest(model: SCLTCPLoginModel(code: i)), to: sock, for: SCLTCPSocketResponse.self)
                            } catch let e {
                                
                            }
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
            print("并发请求")
        }, onError: { _ in
            
        }, onCompleted: {
            
        }).disposed(by: disposeBag)
    }
}
