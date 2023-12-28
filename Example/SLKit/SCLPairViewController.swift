//
//  SCLPairViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/24.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SLKit

class SCLPairViewController: SCLBaseViewController {
    
    private var socket: SLSocketClient?
    
    private var pcPairedDevices: [SCLPCPairedDevice]?
    
    convenience init(sock: SLSocketClient) {
        self.init()
        self.socket = sock
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    private lazy var pairAlertVc = {
        return SCLPairGuideViewController { [unowned self] in
            self.dismiss(animated: true)
        } onPair: { [unowned self] in
            self.getPairedDevices(onPaired: false, button: nil)
        } onPaired: { [unowned self] button in
            self.getPairedDevices(onPaired: true, button: button)
        }
    }()
    
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
    
    private func getPairedDevices(onPaired: Bool, button: UIButton?) {
        guard let socket else {
            dismiss(animated: true) {
                self.presentingViewController?.toast("连接已断开")
            }
            return
        }
        button?.isEnabled = false
        SLSocketManager.shared.send(SCLSocketRequest(content: SCLGetPairedDeviceReq()), to: socket, for: SCLSocketResponse<SCLGetPairedDeviceResp>.self) { [weak self, weak btn = button] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let resp):
                if onPaired {
                    guard let pcPairedDevices else {
                        // 未获取到PC的已配对设备
                        self.toast("未获取到PC已配对的设备")
                        btn?.isEnabled = true
                        return
                    }
                    let deviceList = resp.content?.deviceList ?? []
                    guard !deviceList.isEmpty else {
                        self.toast("蓝牙未配对")
                        btn?.isEnabled = true
                        return
                    }
                    let newDevices = deviceList.filter { new in
                        !pcPairedDevices.contains { old in
                            old == new
                        }
                    }
                    if newDevices.isEmpty {
                        self.toast("蓝牙未配对")
                        btn?.isEnabled = true
                    } else if newDevices.count == 1 {
                        // 认为新增的这个配对设备就是本机
                        self.requestPairVerification(device: newDevices.first!, button: btn)
                    } else {
                        self.transitionToChild(SCLPhonePickerAlertViewController(devices: newDevices, onBack: { [weak self] in
                            if let self {
                                self.transitionToChild(self.pairAlertVc) { childView in }
                            }
                        })) { childView in
                            childView.snp.makeConstraints { make in
                                make.size.equalToSuperview()
                                make.center.equalToSuperview()
                            }
                        }
                    }
                } else {
                    self.pcPairedDevices = resp.content?.deviceList
                    let scheme = "App-Prefs:root=General"
            //        let scheme = "App-Prefs:root=Bluetooth"
                    if let url = URL(string: scheme) {
                        UIApplication.shared.open(url)
                    }
                }
            case .failure(let e):
                self.toast(e.localizedDescription)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func requestPairVerification(device: SCLPCPairedDevice, button: UIButton?) {
        guard let socket else {
            dismiss(animated: true) {
                self.presentingViewController?.toast("连接已断开")
            }
            return
        }
        SLSocketManager.shared.send(SCLSocketRequest(content: SCLPairVerificationReq(device: device)), to: socket, for: SCLSocketResponse<SCLSocketGenericContent>.self) { [weak self, weak btn = button] result in
            guard let self else { return }
            btn?.isEnabled = true
            switch result {
            case .success(let resp):
                if resp.state == 1 {
                    // MARK: 蓝牙配对校验通过
                    self.toast("已完成蓝牙配对，回控功能已启用")
                    self.present(SCLAirPlayGuideViewController(), animated: true)
                } else {
                    // MARK: 蓝牙配对校验未通过
                    self.presentingViewController?.toast("蓝牙配对校验未通过")
                    self.dismiss(animated: true)
                }
            case .failure(let e):
                self.presentingViewController?.toast(e.localizedDescription)
                self.dismiss(animated: true)
            }
        }
    }
}
