//
//  FileDecisionViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/7.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

class FileDecisionViewController: SCLBaseViewController {

    @IBOutlet weak var textLabel: UILabel!
    
    private var deviceName: String?
    private var filesCount: Int?
    private var onRefused: (() -> Void)?
    private var onReceive: (() -> Void)?
    
    convenience init(
        deviceName: String,
        filesCount: Int,
        onRefused: @escaping (() -> Void),
        onReceive: @escaping (() -> Void)
    ) {
        self.init()
        self.deviceName = deviceName
        self.filesCount = filesCount
        self.onRefused = onRefused
        self.onReceive = onReceive
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        textLabel.text = "\(deviceName ?? "")给你发送了\((filesCount ?? 0) > 0 ? "\(filesCount!)个" : "")文件"
    }
    
    @IBAction func onRefuse(sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: {
            self.onRefused?()
        })
    }
    
    @IBAction func onReceive(sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: {
            self.onReceive?()
        })
    }
}
