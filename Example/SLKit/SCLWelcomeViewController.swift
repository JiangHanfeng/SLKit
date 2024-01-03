//
//  SCLWelcomeViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/20.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import SLKit
import LLNetworkAccessibility_Swift

class SCLWelcomeViewController: SCLBaseViewController {
    
    @IBOutlet weak var nsBtn: UIButton!
    
    private lazy var privacyPolicyController = {
        return SCLPrivacyPolicyViewController {  [weak self] allAgreed in
            self?.nsBtn.isEnabled = allAgreed
        }
    }()
    
//    private lazy var getAppPromptController = {
//        return SCLGetAppPromptViewController()
//    }()
    
    private lazy var requestPermissionController = {
        return SCLRequestPermissionViewController()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nsBtn.setBackgroundColor(color: UIColor(displayP3Red: 88/255.0, green: 108/255.0, blue: 255/255.0, alpha: 1), forState: .normal)
        nsBtn.setBackgroundColor(color: UIColor(displayP3Red: 177/255.0, green: 185/255.0, blue: 242/255.0, alpha: 1), forState: .disabled)
        nsBtn.rx.tap.bind { [weak self] in
            guard let self else {
                return
            }
            let configChildView: (UIView) -> Void = { childView in
                childView.snp.makeConstraints { make in
                    make.left.right.equalTo(0)
                    make.top.equalTo(-UIDevice.safeDistanceTop())
                    make.bottom.equalTo(self.nsBtn.snp.top).offset(-32)
                }
            }
            switch self.childViewControllers.last {
            case self.privacyPolicyController:
                self.transitionToChild(self.requestPermissionController, configChildViewRect: configChildView)
                self.nsBtn.setTitle("开始吧", for: .normal)
//            case self.getAppPromptController:
//                self.transitionToChild(self.requestPermissionController, configChildViewRect: configChildView)
//                self.nsBtn.setTitle("开始吧", for: .normal)
            case self.requestPermissionController:
                let requestBt = Observable.create { observer in
                    SLCentralManager.shared.requestPermission { state in
                        if state != .unauthorized {
                            observer.onNext(state)
                            observer.onCompleted()
                        } else {
                            let error = NSError(domain: NSCocoaErrorDomain, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey:"蓝牙未授权"])
                            observer.onError(error)
                        }
                    }
                    return Disposables.create()
                }
                let requestNetwork = Observable.create { observer in
                    LLNetworkAccessibility.start()
                    let currentState = LLNetworkAccessibility.getCurrentAuthState()
                    if currentState == .unknown {
                        LLNetworkAccessibility.reachabilityUpdateCallBack = { state in
                            LLNetworkAccessibility.stop()
                            if let state {
                                switch state {
                                case .available:
                                    observer.onNext(true)
                                    observer.onCompleted()
                                case .restricted:
                                    let error = NSError(domain: NSCocoaErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey:"网络未授权"])
                                    observer.onError(error)
                                default:
                                    observer.onNext(true)
                                    observer.onCompleted()
                                }
                            }
                        }
                    } else {
                        observer.onNext(currentState == .available)
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
                requestBt.flatMap { _ in
                    return requestNetwork
                }.subscribe(onNext: { [weak self] _ in
                    UserDefaults.standard.setValue(true, forKey: SCLUserDefaultKey.agreedPrivacyPolicy.rawValue)
                    UserDefaults.standard.synchronize()
                    self?.navigationController?.show(SCLHomeViewController(), sender: nil)
                }, onError: { [weak self] error in
                    
                }, onCompleted: {
                    
                }).disposed(by: disposeBag)
            default:
                break
            }
        }.disposed(by: disposeBag)
        transitionToChild(privacyPolicyController) { [weak self] childView in
            childView.snp.makeConstraints { make in
                if let self {
                    make.left.right.equalTo(0)
                    make.top.equalTo(-UIDevice.safeDistanceTop())
                    make.bottom.equalTo(self.nsBtn.snp.top).offset(-32)
                }
            }
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

}
