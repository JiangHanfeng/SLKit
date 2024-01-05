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
    
    private var device: SLDevice?
    private var disconnectedCallback: (() -> Void)?
    private var state = State.connected
    private var socketDataListener: SLSocketClientUnhandledDataHandler?
    private var requestPairByDevice = false // 是否从pc发起配对
    private var pcPairedDevices: [SCLPCPairedDevice] = []
    
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
                        self.requestScreen()
                    } else {
                        self.toast("投屏失败")
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
                        self.toast("配对成功")
                    } else {
                        // MARK: 弹出列表供用户选择
                        self.toast("弹出列表供用户选择")
                    }
                default:
                    break
                }
            }
        })
        SLSocketManager.shared.addClientUnhandledDataHandler(socketDataListener!)
//        DispatchQueue.global().async {
//            SLFileTransferManager.share().activate(withDeviceId: SCLUtil.getDeviceMac(), deviceName: SCLUtil.getDeviceName(), bufferSize: 1024 * 1024 * 2, outTime: 5)
//        }
    }

    private func startReconnect() {
        present(SCLReconnectViewController(duration: 30), animated: true)
    }

    @IBAction private func onDisconnect() {
        if let sock = device?.localClient {
            SLSocketManager.shared.send(SCLSocketRequest(content: SCLEndReq(state: 0)), from: sock, for: SCLSocketResponse<SCLSocketGenericContent>.self) { _ in
                
            }
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
            requestScreen()
        default:
            break
        }
    }
    
    private func requestScreen(isInitiative: Bool = true) {
        guard let socket = device?.localClient else {
            return
        }
        guard let mac = SCLUtil.getBTMac(), !mac.isEmpty else {
            present(SCLPairViewController(sock: socket), animated: true)
            return
        }
        Task {
            do {
                if isInitiative {
                    _ = try await SLSocketManager.shared.send(SCLSocketRequest(content: SCLScreenReq(ip: SLNetworkManager.shared.ipv4OfWifi ?? "", port1: 0, port2: 0, port3: 0)), from: socket, for: SCLScreenResp.self)
                }
                _ = try await SLSocketManager.shared.send(SCLSocketRequest(content: SCLInitReq()), from: socket, for: SCLInitResp.self)
                SLSocketManager.shared.send(SCLSocketRequest(content: SCLSocketGenericContent(cmd: .startAirplay)), from: socket, for: SCLSocketResponse<SCLSocketGenericContent>.self) { _ in

                }
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
}
