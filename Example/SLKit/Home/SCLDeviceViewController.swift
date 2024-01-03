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
    
    private var mac: String!
    private var name: String!
    private var socket: SLSocketClient?
    private var disconnectedCallback: (() -> Void)?
    private var state = State.connected
    
    convenience init(socket: SLSocketClient, mac: String, name: String, disconnectedCallback: @escaping () -> Void) {
        self.init()
        self.socket = socket
        self.mac = mac
        self.name = name
        self.disconnectedCallback = disconnectedCallback
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disconenctBtn.setBorder(width: 1, cornerRadius: 15, color: UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1))
        nameLabel.text = name
        socket?.unexpectedDisconnectHandler = { [weak self] error in
            DispatchQueue.main.async {
                self?.connectionStateLabel.text = "已断开连接"
                self?.startReconnect()
            }
        }
        SLFileTransferManager.share().activate(withDeviceId: SCLUtil.getDeviceMac(), deviceName: SCLUtil.getDeviceName(), buferSize: 1024 * 1024 * 2, outTime: 5)
    }

    private func startReconnect() {
        present(SCLReconnectViewController(duration: 30), animated: true)
    }

    @IBAction private func onDisconnect() {
        if let socket {
            SLSocketManager.shared.disconnect(socket) { [weak self] in
                self?.disconnectedCallback?()
            }
        } else {
            disconnectedCallback?()
        }
    }
    
    @IBAction private func onAirplay() {
        switch state {
        case .connected:
            guard let socket else {
                return
            }
            Task {
                do {
                    _ = await try SLSocketManager.shared.send(SCLSocketRequest(content: SCLScreenReq(ip: SLNetworkManager.shared.ipv4OfWifi ?? "", port1: 0, port2: 0, port3: 0)), from: socket, for: SCLScreenResp.self)
                    _ = await try SLSocketManager.shared.send(SCLSocketRequest(content: SCLInitReq()), from: socket, for: SCLInitResp.self)
                    present(SCLAirPlayGuideViewController(), animated: true)
                } catch let e {
                    toast(e.localizedDescription)
                }
            }
//            let pairedMacAddresses = SCLDBManager.getPairedMacAddresses()
//            if pairedMacAddresses.contains(mac) {
//                present(SCLAirPlayGuideViewController(), animated: true)
//            } else {
//                guard let socket else {
//                    toast("已断开连接")
//                    return
//                }
//                present(SCLPairViewController(sock: socket), animated: true)
//            }
        default:
            break
        }
    }
}
