//
//  SCLDeviceViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SLKit

class SCLDeviceViewController: SCLBaseViewController {
    
    enum State {
        case connected
        case airplayRequesting
        case airplay
        case airplayTeminating
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var disconenctBtn: UIButton!
    @IBOutlet weak var airplayBtn: UIButton!
    @IBOutlet weak var fileTransferView: UIView!
    
    private var device: SLDevice?
    private var disconnectedCallback: (() -> Void)?
    private var state = State.connected
    private var socketDataListener: SLSocketClientUnhandledDataHandler?
    private var requestPairByDevice = false // 是否从pc发起配对
    private var pcPairedDevices: [SCLPCPairedDevice] = []
    private var airplaySuccess = false {
        didSet {
            airplayBtn.setTitle(airplaySuccess ? "停止投屏" : "开始投屏", for: .normal)
            if airplaySuccess && hidConnected {
                calibrationIfNeed()
            }
        }
    }
    
    private var hidConnected = false {
        didSet {
            if airplaySuccess && hidConnected {
                calibrationIfNeed()
            }
        }
    }
    
    convenience init(device: SLDevice, disconnectedCallback: @escaping () -> Void) {
        self.init()
        self.device = device
        self.disconnectedCallback = disconnectedCallback
    }
    
    deinit {
        if let socketDataListener {
            SLSocketManager.shared.removeClientUnhandledDataHandler(socketDataListener)
        }
        SLLog.debug("\(self) deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disconenctBtn.setBorder(width: 1, cornerRadius: 15, color: UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1))
        nameLabel.text = device?.name
        socketDataListener = SLSocketClientUnhandledDataHandler(id: String(describing: self), handle: { [weak self] data, client in
            guard let self else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any], let dict = json else { return }
            guard let cmd = dict["cmd"] as? Int else {
                return
            }
            DispatchQueue.main.async {
                switch cmd {
                case SCLCmd.requestScreen.rawValue:
                    self.requestScreen()
                case SCLCmd.stopAirplay.rawValue:
                    self.dismiss(animated: true)
                case SCLCmd.airplayUpdated.rawValue:
                    self.dismiss(animated: true)
                    var result = false
                    if let state = dict["state"] as? Int {
                        result = state == 1
                    }
                    if result {
                        SLLog.debug("投屏成功")
                        self.toast("投屏成功")
                        let mac = SCLUtil.getBTMac()
                        if mac?.isEmpty ?? true {
                            if let device = self.device {
                                self.present(SCLPairViewController(device: device), animated: true)
                            } else {
                                SLLog.debug("检测到蓝牙未配对，弹窗提示时socket已释放")
                            }
                        }
                        self.airplaySuccess = true
                    } else {
                        SLLog.debug("投屏失败")
                        self.toast("投屏失败")
                        self.airplaySuccess = false
                    }
                case SCLCmd.requestPair.rawValue:
                    // 从pc发起的配对请求，state 1表示发起配对，0表示取消配对
                    let stateRange = 0...1
                    guard let state = dict["state"] as? Int, stateRange.contains(state) else {
                        SLLog.debug("pc配对请求参数错误")
                        break
                    }
                    self.pcPairedDevices = []
                    self.requestPairByDevice = state == 1
                    if 
                        self.requestPairByDevice,
                        let deviceList = dict["deviceList"] as? [String],
                        !deviceList.isEmpty
                    {
                        for deviceJsonString in deviceList {
                            if let device = SCLPCPairedDevice.deserialize(from: deviceJsonString) {
                                self.pcPairedDevices.append(device)
                            }
                        }
                    }
                case SCLCmd.pairCompleted.rawValue:
                    var list: [SCLPCPairedDevice] = []
                    if let deviceList = dict["deviceList"] as? [String], !deviceList.isEmpty {
                        for deviceJsonString in deviceList {
                            if let device = SCLPCPairedDevice.deserialize(from: deviceJsonString) {
                                list.append(device)
                            }
                        }
                    }
                    // MARK: diff
                    let newDevices = list.filter { new in
                        !self.pcPairedDevices.contains { old in
                            old == new
                        }
                    }
                    if newDevices.count == 1 {
                        // MARK: 认为本机是此设备
                        SLLog.debug("配对成功，本机mac：\(newDevices.first!.mac)，本机名称：\(newDevices.first!.deviceName)")
                        self.submitPairResult(pairedDevice: newDevices.first!, result: true)
                    } else {
                        // MARK: 弹出列表供用户选择
                        if let device = self.device {
                            self.present(SCLPairViewController(device: device), animated: true)
                        } else {
                            SLLog.debug("检测到蓝牙未配对，弹窗提示时socket已释放")
                        }
                    }
                case SCLCmd.hidConnected.rawValue:
                    var state: Int?
                    if let intValue = dict["state"] as? Int {
                        state = intValue
                    } else if let stringValue = dict["state"] as? String {
                        state = Int(stringValue)
                    }
                    self.hidConnected = state == 0
                default:
                    break
                }
            }
        })
        SLSocketManager.shared.addClientUnhandledDataHandler(socketDataListener!)
//        DispatchQueue.global().async {
//            SLFileTransferManager.share().activate(withDeviceId: SCLUtil.getDeviceMac(), deviceName: SCLUtil.getDeviceName(), bufferSize: 1024 * 1024 * 2, outTime: 5)
//        }
        if let socket = device?.localClient {
            SLSocketManager.shared.send(SCLSocketRequest(content: SCLScreenReq(ip: SLNetworkManager.shared.ipv4OfWifi ?? "", port1: 0, port2: UInt16(SLTransferManager.share().controlPort), port3: UInt16(SLTransferManager.share().dataPort))), from: socket, for: SCLScreenResp.self) { result in
                switch result {
                case .success(let resp):
                    SLTransferManager.share().configSendInfo(withDeviceId: self.device?.id ?? "", ip: self.device?.localClient.host ?? "", controlPort: Int32(resp.port2), dataPort: Int32(resp.port3))
                case .failure(_):
                    break
                }
            }
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onFileTransfer))
        fileTransferView.isUserInteractionEnabled = true
        fileTransferView.addGestureRecognizer(tap)
    }

    private func startReconnect() {
        present(SCLReconnectViewController(duration: 30), animated: true)
    }

    @IBAction private func onDisconnect() {
        if let sock = device?.localClient {
//            SLSocketManager.shared.send(request: SCLSocketRequest(content: SCLEndReq(state: 0)), from: sock) { _ in }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(125), execute: {
                SLSocketManager.shared.disconnect(sock) { [weak self] in
                    DispatchQueue.main.async {
                        self?.disconnectedCallback?()
                    }
                }
            })
        } else {
            disconnectedCallback?()
        }
    }
    
    @IBAction private func onAirplay() {
        switch state {
        case .connected:
            airplaySuccess ? cancelScreen() : requestScreen()
        default:
            break
        }
    }
    
    @objc private func onFileTransfer() {
        (UIApplication.shared.delegate as? AppDelegate)?.selectFile()
    }
    
    private func requestScreen(isInitiative: Bool = true) {
        guard let socket = device?.localClient else {
            return
        }
        Task {
            do {
                if isInitiative {
                    _ = try await SLSocketManager.shared.send(SCLSocketRequest(content: SCLScreenReq(ip: SLNetworkManager.shared.ipv4OfWifi ?? "", port1: 0, port2: UInt16(SLTransferManager.share().controlPort), port3: UInt16(SLTransferManager.share().dataPort))), from: socket, for: SCLScreenResp.self)
                }
                _ = try await SLSocketManager.shared.send(SCLInitReq(mac: SCLUtil.getBTMac() ?? ""), from: socket, for: SCLInitResp.self)
//                SLSocketManager.shared.send(request: SCLSocketRequest(content: SCLSocketGenericContent(cmd: .startAirplay)), from: socket) { _ in }
                present(SCLAirPlayGuideViewController(onCancel: {
                    let completion = {
                        SLSocketManager.shared.send(SCLSocketRequest(content: SCLSocketGenericContent(cmd: .stopAirplay)), from: socket, for: SCLSocketResponse<SCLSocketGenericContent>.self) { _ in
                            
                        }
                    }
                    self.dismiss(animated: true, completion: completion)
                }), animated: true)
            } catch let e {
                toast(e.localizedDescription)
            }
        }
    }
    
    private func cancelScreen() {
        defer {
            airplaySuccess = false
        }
        guard let socket = device?.localClient else {
            return
        }
//        SLSocketManager.shared.send(request: SCLSocketRequest(content: SCLSocketGenericContent(cmd: .stopAirplay)), from: socket) { _ in }
    }
    
    private func submitPairResult(pairedDevice: SCLPCPairedDevice, result: Bool) {
        SLLog.debug("提交蓝牙配对校验结果：\(result ? "通过" : "未通过")")
        defer {
            if result {
                _ = SCLUtil.setBTMac(pairedDevice.mac)
                _ = SCLUtil.setDeviceName(pairedDevice.deviceName)
            }
        }
        
        if let socket = device?.localClient {
            SLSocketManager.shared.send(SCLSocketRequest(content: SCLSyncPairReq(device: pairedDevice, state: result ? 1 : 0)), from: socket, for: SCLSocketResponse<SCLSocketGenericContent>.self) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let resp):
                    if resp.state == 1 {
                        // MARK: 蓝牙配对校验通过
                        self.toast("已完成蓝牙配对，回控功能已启用")
                    } else {
                        // MARK: 蓝牙配对校验未通过
                        self.toast("蓝牙配对校验未通过")
                    }
                case .failure(_):
                    break
                }
            }
        }
    }
    
    private func calibrationIfNeed() {
        let needCalibratiopn =  SCLUtil.getCalibrationData()?.isEmpty ?? true
        SLLog.debug("投屏成功，hid已连接，\(needCalibratiopn ? "需要" : "不需要")校准")
        guard let device = self.device else {
            SLLog.debug("启动校准失败：当前设备已被释放")
            return
        }
        if let presentedViewController {
            if !presentedViewController.isKind(of: SLAdjustingViewController.self) {
                dismiss(animated: true) {
                    self.present(SLAdjustingViewController(initiative: false, device: device), animated: true)
                }
            }
        } else {
            present(SLAdjustingViewController(initiative: false, device: device), animated: true)
        }
    }
}
