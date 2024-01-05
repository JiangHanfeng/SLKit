//
//  SCLWelcomeViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/20.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import CoreLocation
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
    
    private lazy var locationManager = {
        return CLLocationManager()
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
                let requestLocalNetwork = Observable.create { observer in
                    SLNetworkManager.shared.requestLocalNetworkPermission { granted in
                        observer.onNext(granted)
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
                    return requestLocalNetwork
                }.subscribe(onNext: { [weak self] result in
                    if result {
                        self?.locationManager.delegate = self
                        self?.locationManager.requestAlwaysAuthorization()
                    } else {
                        self?.toast("您拒绝了访问“本地网络”")
                    }
                }, onError: { _ in
                    
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

extension SCLWelcomeViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        var locationAuthStatus: CLAuthorizationStatus?
        if #available(iOS 14.0, *) {
            locationAuthStatus = locationManager.authorizationStatus
        } else {
            locationAuthStatus = CLLocationManager.authorizationStatus()
        }
        guard locationAuthStatus == .authorizedAlways || locationAuthStatus == .authorizedWhenInUse else {
            return
        }
        UserDefaults.standard.setValue(true, forKey: SCLUserDefaultKey.agreedPrivacyPolicy.rawValue)
        UserDefaults.standard.synchronize()
        navigationController?.show(SCLHomeViewController(), sender: nil)
    }
}
