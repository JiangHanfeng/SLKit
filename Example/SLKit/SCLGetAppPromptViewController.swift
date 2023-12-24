//
//  SCLGetAppPromptViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/20.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLGetAppPromptViewController: SCLBaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction private func onCopy() {
        UIPasteboard.general.string = "www.freestyle.com"
        toast("复制成功")
    }

}
