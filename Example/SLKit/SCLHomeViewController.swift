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
        Task {
            do {
                let response = try await SLTCPManager.shared().asyncRequest(host: "192.168.3.170", port: 8088, taskId: "", text: "heart")
                if let string = String(data: response, encoding: .utf8) {
                    self.toast("收到响应:\(string)")
                }
            } catch let error {
                self.toast(error.localizedDescription)
            }
        }
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
