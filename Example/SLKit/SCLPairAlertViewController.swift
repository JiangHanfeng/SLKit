//
//  SCLPairAlertViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/19.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import SLKit

class SCLPairAlertViewController: SCLBaseViewController {
    
    @IBOutlet private weak var cancelBtn: UIButton!
    @IBOutlet private weak var pairBtn: UIButton!
    @IBOutlet private weak var pairedBtn: UIButton!
    @IBOutlet private weak var pairedBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var pairedBtnBottomConstraint: NSLayoutConstraint!
    
    private var cancel: (() -> Void)?
    private var pair: (() -> Void)?
    private var paired: (() -> Void)?
    
    convenience init(
        onCancel: @escaping (() -> Void),
        onPair: @escaping (() -> Void),
        onPaired: @escaping (() -> Void)
    ) {
        self.init()
        self.cancel = onCancel
        self.pair = onPair
        self.paired = onPaired
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelBtn.layer.borderColor = UIColor.init(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1).cgColor
//        SLLog.debug("socket开始连接")
//        let task = SLSocketClient(host: "", port: 0)
//        task.rx.connection.flatMap({ _ in
//            SLLog.debug("socket已连接")
//            return task.rx.listen
//        }).subscribe(onNext: { str in
//            SLLog.debug("socket收到:\(str)")
//        }, onError: { _ in
//            SLLog.debug("onError")
//        }, onCompleted: {
//            SLLog.debug("onCompleted")
//        }).disposed(by: disposeBag)
        setPairedBtn(hidden: true)
    }
    
    @IBAction private func onCancel() {
        cancel?()
    }
    
    @IBAction private func onPair() {
        pair?()
        setPairedBtn(hidden: false)
    }
    
    @IBAction private func onPaired() {
//        present(SCLPhonePickerAlertViewController(), animated: true)
        paired?()
    }
    
    private func setPairedBtn(hidden: Bool) {
        pairedBtn.alpha = hidden ? 1 : 0
        pairedBtnBottomConstraint.constant = hidden ? 0 : 32
        pairedBtnHeightConstraint.constant = hidden ? 0 : 44
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.pairedBtn.alpha = hidden ? 0 : 1
            self?.view.layoutIfNeeded()
        } completion: { _ in

        }

    }

}
