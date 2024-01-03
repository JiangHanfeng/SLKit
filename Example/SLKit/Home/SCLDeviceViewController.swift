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
    
    convenience init(device: SLDevice, disconnectedCallback: @escaping () -> Void) {
        self.init()
        self.device = device
        self.disconnectedCallback = disconnectedCallback
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disconenctBtn.setBorder(width: 1, cornerRadius: 15, color: UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1))
        nameLabel.text = device?.name
//        switch device?.role {
//        case .client(_):
//            disconnectedCallback?()
//        case .server(let sLSocketClient):
//            sLSocketClient.unexpectedDisconnectHandler = { [weak self] error in
//                DispatchQueue.main.async {
//                    self?.connectionStateLabel.text = "已断开连接"
//                    self?.startReconnect()
//                }
//            }
//        case nil:
//            break
//        }
        SLFileTransferManager.share().activate(withDeviceId: SCLUtil.getDeviceMac(), deviceName: SCLUtil.getDeviceName(), bufferSize: 1024 * 1024 * 2, outTime: 5)
    }

    private func startReconnect() {
        present(SCLReconnectViewController(duration: 30), animated: true)
    }

    @IBAction private func onDisconnect() {
        switch device?.role {
        case .client(let port, _):
            SLSocketManager.shared.stopListen(port: port) { [weak self] in
                self?.disconnectedCallback?()
            }
        case .server(let sLSocketClient):
            SLSocketManager.shared.disconnect(sLSocketClient) { [weak self] in
                self?.disconnectedCallback?()
            }
        case nil:
            disconnectedCallback?()
        }
    }
    
    @IBAction private func onAirplay() {
        switch state {
        case .connected:
            switch device?.role {
            case .client(_, _):
                break
            case .server(let socket):
                Task {
                    do {
                        _ = try await SLSocketManager.shared.send(SCLSocketRequest(content: SCLScreenReq(ip: SLNetworkManager.shared.ipv4OfWifi ?? "", port1: 0, port2: 0, port3: 0)), from: socket, for: SCLScreenResp.self)
                        _ = try await SLSocketManager.shared.send(SCLSocketRequest(content: SCLInitReq()), from: socket, for: SCLInitResp.self)
                        present(SCLAirPlayGuideViewController(), animated: true)
                    } catch let e {
                        toast(e.localizedDescription)
                    }
                }
            case nil:
                break
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
