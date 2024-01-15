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
    @IBOutlet weak var sendPhotoView: UIView!
    @IBOutlet weak var sendPhotoMaskView: UIView!
    @IBOutlet weak var sendFileMaskView: UIView!
    @IBOutlet weak var fileTransferView: UIView!
    @IBOutlet weak var fileTransferTitleLabel: UILabel!
    @IBOutlet weak var sendingView: UIView!
    @IBOutlet weak var sendingViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendingViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendingProgressLabel: UILabel!
    @IBOutlet weak var sendingProgressView: UIProgressView!
    
    private var device: SLDevice?
    private var sendingTaskId: String?
    private var disconnectedCallback: ((_ isInitiative: Bool) -> Void)?
    private var state = State.connected
    private var socketDataListener: SLSocketClientUnhandledDataHandler?
    private var requestPairByDevice = false // 是否从pc发起配对
    private var pcPairedDevices: [SCLPCPairedDevice] = []
    var airplaySuccess = false {
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
    
    convenience init(device: SLDevice, disconnectedCallback: @escaping (_ isInitiative: Bool) -> Void) {
        self.init()
        self.device = device
        self.disconnectedCallback = disconnectedCallback
    }
    
    deinit {
        if let socketDataListener {
            SLSocketManager.shared.removeClientUnhandledDataHandler(socketDataListener)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disconenctBtn.setBorder(width: 1, cornerRadius: 15, color: UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1))
        nameLabel.text = device?.name
        // MARK: 设置pc主动发送的消息监听
        socketDataListener = SLSocketClientUnhandledDataHandler(id: String(describing: self), handle: { [weak self] data, client in
            guard let self else { return }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any] else { return }
            guard let cmd = json["cmd"] as? Int else {
                return
            }
            DispatchQueue.main.async {
                switch cmd {
                case SCLCmd.end.rawValue:
                    self.disconnect(isInitiative: false)
                case SCLCmd.requestScreen.rawValue:
                    self.requestScreen()
                case SCLCmd.stopAirplay.rawValue:
                    self.dismiss(animated: true)
                    self.cancelScreen(isInitiative: false)
                case SCLCmd.airplayUpdated.rawValue:
                    self.dismiss(animated: true)
                    var result = false
                    if let state = json["state"] as? Int {
                        result = state == 1
                    }
                    if result {
                        SLLog.debug("投屏状态：投屏中")
                        self.toast("投屏成功")
                        let mac = SCLUtil.getBTMac()
                        if mac?.isEmpty ?? true {
                            if let device = self.device {
                                self.present(SCLPairViewController(device: device), animated: true)
                            } else {
                                SLLog.debug("检测到蓝牙未配对，弹窗提示时socket已释放")
                            }
                        } else if let calibrationData = SCLUtil.getCalibrationData(), !calibrationData.isEmpty, let socket = self.device?.localClient {
                            SLSocketManager.shared.send(
                                SCLSocketRequest(content: SCLUploadCalibrationDataReq(data: calibrationData)),
                                from: socket,
                                for: SCLSocketResponse<SCLUploadCalibrationDataResp>.self)
                            { result in
                                var error: String?
                                switch result {
                                case .success(let resp):
                                    error = resp.content?.succ == 1 ? nil : "upload adjusting data failed"
                                case .failure(let e):
                                    error = e.localizedDescription
                                }
                                DispatchQueue.main.async {
                                    if let error {
                                        SLLog.debug("上传校准数据失败\n\(error.localizedLowercase)")
                                    } else {
                                        SLLog.debug("上传校准数据成功")
                                    }
                                }
                            }
                        }
//                        if SCLUtil.isFirstAirPlay(), let device = self.device {
//                            self.present(SCLPairViewController(device: device), animated: true)
//                        }
                        self.airplaySuccess = true
                    } else {
                        SLLog.debug("投屏状态：断开")
                        if self.airplaySuccess {
                            self.toast("已断开投屏")
                        }
                        self.airplaySuccess = false
                    }
                case SCLCmd.requestPair.rawValue:
                    // 从pc发起的配对请求，state 1表示发起配对，0表示取消配对
                    let stateRange = 0...1
                    guard let state = json["state"] as? Int, stateRange.contains(state) else {
                        SLLog.debug("pc配对请求参数错误")
                        break
                    }
                    self.pcPairedDevices = []
                    self.requestPairByDevice = state == 1
                    if 
                        self.requestPairByDevice,
                        let deviceList = json["deviceList"] as? [String],
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
                    if let deviceList = json["deviceList"] as? [String], !deviceList.isEmpty {
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
                    if let intValue = json["state"] as? Int {
                        state = intValue
                    } else if let stringValue = json["state"] as? String {
                        state = Int(stringValue)
                    }
                    self.hidConnected = state == 0
                default:
                    break
                }
            }
        })
        SLSocketManager.shared.addClientUnhandledDataHandler(socketDataListener!)
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
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onSendPhoto))
        sendPhotoView.isUserInteractionEnabled = true
        sendPhotoView.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(onFileTransfer))
        fileTransferView.isUserInteractionEnabled = true
        fileTransferView.addGestureRecognizer(tap2)
    }

    private func startReconnect() {
        present(SCLReconnectViewController(duration: 30), animated: true)
    }

    @IBAction private func onDisconnect() {
        SLLog.debug("点击断开连接")
        disconnect()
    }
    
    @IBAction private func onAirplay() {
        switch state {
        case .connected:
            airplaySuccess ? cancelScreen() : requestScreen()
        default:
            break
        }
    }
    
    @objc private func onSendPhoto() {
        if
            let transfer = SLTransferManager.share().currentSendFileTransfer(),
            transfer.files.count > 0 || !SLTransferManager.share().currentReceiveFileTransfer().isEmpty {
            toast("当前文件传输中，请在传输结束后发送")
            return
        }
        (UIApplication.shared.delegate as? AppDelegate)?.sendPhoto()
    }
    
    @objc private func onFileTransfer() {
        if
            let transfer = SLTransferManager.share().currentSendFileTransfer(),
            transfer.files.count > 0 || !SLTransferManager.share().currentReceiveFileTransfer().isEmpty {
            toast("当前文件传输中，请在传输结束后发送")
            return
        }
        (UIApplication.shared.delegate as? AppDelegate)?.selectFile()
    }
    
    private func disconnect(isInitiative: Bool = true) {
        SLLog.debug("断开连接：\(isInitiative ? "主动" : "被动")")
        if let sock = device?.localClient {
            if isInitiative {
                SLSocketManager.shared.send(request: SCLSocketRequest(content: SCLEndReq(state: 0)), from: sock) { _ in }
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(125), execute: {
                    SLSocketManager.shared.disconnect(sock) { [weak self] in
                        DispatchQueue.main.async {
                            self?.disconnectedCallback?(isInitiative)
                        }
                    }
                })
            } else {
                SLSocketManager.shared.disconnect(sock) { [weak self] in
                    DispatchQueue.main.async {
                        self?.disconnectedCallback?(isInitiative)
                    }
                }
            }
        } else {
            disconnectedCallback?(isInitiative)
        }
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
                SLSocketManager.shared.send(request: SCLSocketRequest(content: SCLSocketGenericContent(cmd: .startAirplay)), from: socket) { _ in }
                present(SCLAirPlayGuideViewController(onCancel: {
                    let completion = {
                        self.cancelScreen()
                    }
                    self.dismiss(animated: true, completion: completion)
                }), animated: true)
            } catch let e {
                toast(e.localizedDescription)
            }
        }
    }
    
    private func cancelScreen(isInitiative: Bool = true) {
        defer {
            airplaySuccess = false
        }
        guard isInitiative else {
            return
        }
        guard let socket = device?.localClient else {
            return
        }
        SLSocketManager.shared.send(request: SCLSocketRequest(content: SCLSocketGenericContent(cmd: .stopAirplay)), from: socket) { _ in }
    }
    
    private func submitPairResult(pairedDevice: SCLPCPairedDevice, result: Bool) {
        SLLog.debug("提交蓝牙配对校验结果：\(result ? "通过" : "未通过")")
        defer {
            if result && SCLUtil.setBTMac(pairedDevice.mac) {
                SLLog.debug("已保存蓝牙mac:\(pairedDevice.mac)")
                _ = SCLUtil.setDeviceName(pairedDevice.deviceName)
            }
        }
        
        if let socket = device?.localClient {
            // MARK: 本机确认配对成功，只发送，无需等pc回复
            SLSocketManager.shared.send(request: SCLSyncPairReq(device: pairedDevice, pairResult: result), from: socket) { [weak self] resp in
                    guard let self else { return }
                    switch resp {
                    case .success(_):
                        // MARK: 蓝牙配对校验通过
                        self.toast("已完成蓝牙配对，回控功能已启用", image: UIImage(named: "icon_correct_circle_blue"))
                    case .failure(_):
                        // MARK: 蓝牙配对校验未通过
                        self.toast("已完成蓝牙配对，pc同步失败")
                    }
            }
        }
    }
    
    private func calibrationIfNeed() {
        let calibrationData = SCLUtil.getCalibrationData() ?? ""
        let needCalibration = calibrationData.isEmpty
        guard needCalibration else {
            SLLog.debug("投屏成功，hid已连接，不需要校准，准备提交校准数据")
            if let socket = device?.localClient {
                SLSocketManager.shared.send(
                    SCLSocketRequest(content: SCLUploadCalibrationDataReq(data: calibrationData)),
                    from: socket,
                    for: SCLSocketResponse<SCLUploadCalibrationDataResp>.self)
                { result in
                    var error: String?
                    switch result {
                    case .success(let resp):
                        error = resp.content?.succ == 1 ? nil : "upload adjusting data failed"
                    case .failure(let e):
                        error = e.localizedDescription
                    }
                    DispatchQueue.main.async {
                        if let error {
                            SLLog.debug("上传校准数据失败\n\(error.localizedLowercase)")
                        } else {
                            SLLog.debug("上传校准数据成功")
                        }
                    }
                }
            } else {
                SLLog.debug("上传校准数据失败:socket已被释放")
            }
            return
        } 
        SLLog.debug("投屏成功，hid已连接，需要校准")
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
    
    func updateSendingProgress(_ progress: Float, taskId: String) {
        sendingTaskId = taskId
        let intProgress = Int(progress * 100)
        sendingProgressLabel.text = "\(intProgress)%"
        sendingProgressView.progress = progress
    }
    
    func showSendingView() {
        fileTransferTitleLabel.text = "文件发送中"
        sendingProgressLabel.text = "0%"
        sendingProgressView.progress = 0
        sendingView.alpha = 0
        sendingView.isHidden = false
        sendingViewTopConstraint.constant = 10
        sendingViewHeightConstraint.constant = 58
        UIView.animate(withDuration: 0.25) {
            self.sendingView.alpha = 1
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.sendingView.alpha = 1
        }
    }
    
    func hideSendingView() {
        fileTransferTitleLabel.text = "文件传输"
        sendingView.alpha = 1
        sendingView.isHidden = false
        sendingViewTopConstraint.constant = 0
        sendingViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.sendingView.alpha = 0
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.sendingView.alpha = 0
            self?.sendingView.isHidden = true
            self?.sendingProgressLabel.text = "0%"
            self?.sendingProgressView.progress = 0
        }
    }
    
    func switchSendable(_ sendable: Bool) {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.sendPhotoMaskView.isHidden = sendable
            self?.sendFileMaskView.isHidden = sendable
        } completion: { [weak self] _ in
            self?.sendPhotoMaskView.isHidden = sendable
            self?.sendFileMaskView.isHidden = sendable
        }
    }
    
    @IBAction func onCancelSendFile(sender: UIButton) {
        if let sendingTaskId {
            SLTransferManager.share().cancelFiles(withTaskId: sendingTaskId)
        }
    }
}
