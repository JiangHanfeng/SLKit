//
//  SCLPairViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/24.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLPairViewController: SCLBaseViewController {
    
    private lazy var pairAlertVc = {
        return SCLPairAlertViewController { [unowned self] in
            self.dismiss(animated: true)
        } onPair: { [weak self] in
            let scheme = "App-Prefs:root=General"
    //        let scheme = "App-Prefs:root=Bluetooth"
            if let url = URL(string: scheme) {
                UIApplication.shared.open(url)
            }
        } onPaired: { [unowned self] in
            self.transitionToChild(self.phonePickerVc, configChildViewRect: { childView in
                childView.snp.makeConstraints { make in
                    make.size.equalToSuperview()
                    make.center.equalToSuperview()
                }
            })
        }
    }()
    
    private lazy var phonePickerVc = {
        return SCLPhonePickerAlertViewController { [unowned self] in
            self.dismiss(animated: true)
        }
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.6)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transitionToChild(pairAlertVc) { childView in
            childView.snp.makeConstraints { make in
                make.size.equalToSuperview()
                make.center.equalToSuperview()
            }
        }
    }

}
