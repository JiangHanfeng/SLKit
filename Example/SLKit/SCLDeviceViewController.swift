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
            let pairedMacAddresses = SCLDBManager.getPairedMacAddresses()
            if pairedMacAddresses.contains(mac) {
                
            } else {
                present(SCLPairViewController(), animated: true)
            }
        default:
            break
        }
    }
}
