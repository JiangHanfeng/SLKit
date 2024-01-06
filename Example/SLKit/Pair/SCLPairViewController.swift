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
    
    private var a2dpMonitorTask: SLA2DPMonitorTask?
    private var a2dpDevice: SLA2DPDevice?
    
    convenience init(sock: SLSocketClient, deviceList: [SCLPCPairedDevice]? = nil) {
        self.init()
        self.socket = sock
        self.pcPairedDevices = deviceList
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }
    
    deinit {
        print("\(self) deinit")
        a2dpMonitorTask?.terminate()
    }
    
    private lazy var pairAlertVc = {
        return SCLPairGuideViewController { [unowned self] in
            self.dismiss(animated: true)
        } onPair: { [unowned self] in
            // MARK: 获取pc的已配对列表，开启A2DP检测，跳转到设置
            self.getPairedDevices(onPaired: false, button: nil)
            if self.a2dpMonitorTask == nil {
                self.a2dpMonitorTask = SLA2DPMonitorTask(connectedCallback: { [weak self] device in
                    self?.a2dpDevice = device
                    SLLog.debug("检测到已连接a2dp:\(device.uid)")
                }, updatededCallback: { [weak self] device in
                    self?.a2dpDevice = device
                    SLLog.debug("检测到已更新a2dp:\(device.uid)")
                }, disconnectedCallback: { [weak self] device in
                    self?.a2dpDevice = nil
                    SLLog.debug("检测到已断开a2dp:\(device.uid)")
                })
            }
            self.a2dpMonitorTask?.start()
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
        if let pcPairedDevices, !pcPairedDevices.isEmpty {
            transitionToPhonePicker(devices: pcPairedDevices.reversed())
        } else {
            transitionToChild(pairAlertVc) { childView in
                childView.snp.makeConstraints { make in
                    make.size.equalToSuperview()
                    make.center.equalToSuperview()
                }
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
        SLSocketManager.shared.send(SCLSocketRequest(content: SCLSocketGenericContent(cmd: .getPairedDevices)), from: socket, for: SCLSocketResponse<SCLGetPairedDeviceResp>.self) { [weak self, weak btn = button] result in
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
                    SLLog.debug("newDevices.count = \(newDevices.count)")
                    if newDevices.count == 1 {
                        // 认为新增的这个配对设备就是本机，暂时不考虑判断a2dp连接状态
//                        self.requestPairVerification(device: newDevices.first!, button: btn)
                        self.submitPairResult(device: newDevices.first!, result: true)
                    } else {
                        // MARK: diff两次列表，相差不为1，让用户选择
                        self.transitionToPhonePicker(devices: newDevices.isEmpty ? deviceList.reversed() : newDevices.reversed())
                    }
                } else {
                    // MARK: 点击已配对获取到列表后跳转设置
                    self.pcPairedDevices = resp.content?.deviceList
                    let scheme = "App-Prefs:root=General"
            //        let scheme = "App-Prefs:root=Bluetooth"
                    if let url = URL(string: scheme) {
                        UIApplication.shared.open(url)
                    }
                    button?.isEnabled = true
                }
            case .failure(let e):
                self.toast(e.localizedDescription)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func requestPairVerification(device: SCLPCPairedDevice, button: UIButton?) {
        guard let socket else {
            let presentingVc = presentingViewController
            presentingVc?.dismiss(animated: true) {
                presentingVc?.toast("连接已断开")
            }
            return
        }
        SLLog.debug("请求蓝牙配对校验")
        SLSocketManager.shared.send(SCLPairVerificationReq(device: device), from: socket, for: SCLSocketResponse<SCLSocketGenericContent>.self) { [weak self, weak btn = button] result in
            guard let self else { return }
            btn?.isEnabled = true
            switch result {
            case .success(let resp):
                if resp.state == 1 {
                    // MARK: 蓝牙配对校验通过
                    self.presentingViewController?.toast("已完成蓝牙配对，回控功能已启用")
                } else {
                    // MARK: 蓝牙配对校验未通过
                    self.presentingViewController?.toast("蓝牙配对校验未通过")
                }
                self.presentingViewController?.dismiss(animated: true)
            case .failure(let e):
                self.presentingViewController?.toast(e.localizedDescription)
                self.dismiss(animated: true)
            }
        }
    }
    
    private func submitPairResult(device: SCLPCPairedDevice, result: Bool) {
        defer {
            if result {
                _ = SCLUtil.setBTMac(device.mac)
            }
            let presentingVc = presentingViewController
            let completion = {
                if !result {
                    presentingVc?.toast("蓝牙配对校验失败")
                }
            }
            presentingViewController?.dismiss(animated: true, completion: completion)
        }
        
        if let socket {
            SLSocketManager.shared.send(SCLSocketRequest(content: SCLSyncPairReq(device: device, state: result ? 1 : 0)), from: socket, for: SCLSocketResponse<SCLSocketGenericContent>.self) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let resp):
                    if resp.state == 1 {
                        // MARK: 蓝牙配对校验通过
                        self.presentingViewController?.toast("已完成蓝牙配对，回控功能已启用")
                    } else {
                        // MARK: 蓝牙配对校验未通过
                        self.presentingViewController?.toast("蓝牙配对校验未通过")
                    }
                    self.presentingViewController?.dismiss(animated: true)
                case .failure(_):
    //                self.presentingViewController?.toast(e.localizedDescription)
    //                self.dismiss(animated: true)
                    break
                }
            }
        }
    }
    
    /// 跳转至设备列表
    private func transitionToPhonePicker(devices: [SCLPCPairedDevice]) {
        guard let socket else {
            presentingViewController?.dismiss(animated: true, completion: {
                self.presentingViewController?.toast("已断开连接")
            })
            return
        }
        transitionToChild(SCLPhonePickerAlertViewController(socket: socket, devices: devices, onVerified: { [weak self] device in
//                            if self?.a2dpDevice?.uid.elementsEqual(device.mac) == true {
                self?.submitPairResult(device: device, result: true)
                let presentingVc = self?.presentingViewController
                presentingVc?.dismiss(animated: true, completion: {
                    presentingVc?.toast("配对校验通过")
                })
//                            } else {
//                                self?.toast("配对校验未通过")
//                            }
        }, onBack: { [weak self] in
            if let self {
                self.presentingViewController?.dismiss(animated: true)
            }
        })) { childView in
            childView.snp.makeConstraints { make in
                make.size.equalToSuperview()
                make.center.equalToSuperview()
            }
        }
    }
}
