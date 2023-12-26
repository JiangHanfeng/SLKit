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
    
    private lazy var connectionVc: SCLConnectionViewController = {
        return SCLConnectionViewController { [weak self] in
            guard let self else {
                return
            }
            self.transitionToChild(deviceVc, removeCurrent: false) { childView in
                childView.snp.makeConstraints { make in
                    make.top.equalTo(self.topBar.snp.bottom)
                    make.left.right.equalTo(0)
                    make.bottom.equalTo(-UIDevice.safeDistanceBottom())
                }
            }
        }
    }()
    
    private lazy var deviceVc: SCLDeviceViewController = {
        return SCLDeviceViewController { [weak self] in
            guard let self else {
                return
            }
            self.transitionToChild(connectionVc, removeCurrent: false) { childView in
                childView.snp.makeConstraints { make in
                    make.top.equalTo(self.topBar.snp.bottom)
                    make.left.right.equalTo(0)
                    make.bottom.equalTo(-UIDevice.safeDistanceBottom())
                }
            }
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: true)
        transitionToChild(connectionVc) { childView in
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
//        navigationController?.show(SCLFileHistoryViewController(), sender: nil)
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

//        Task {
//            do {
//                let response = try await SLTCPManager.shared().asyncRequest(host: "192.168.3.170", port: 8088, taskId: "", text: "heart")
//                if let string = String(data: response, encoding: .utf8) {
//                    self.toast("收到响应:\(string)")
//                }
//            } catch let error {
//                self.toast(error.localizedDescription)
//            }
//        }
    }
    
    @IBAction private func onSetting() {
        navigationController?.show(SCLSettingViewController(), sender: nil)
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
    
    func test() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                Thread.sleep(forTimeInterval: 3)
                continuation.resume(returning: true)
            }
        }
    }
}
