//
//  TestViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/11/6.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SLKit
import CoreBluetooth

class TestViewController: UIViewController {

    @IBOutlet weak var bleOperationBtn: UIButton!
    @IBOutlet weak var bleStatusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private let pc_ble_uuid = "0000180a-0000-1000-8000-00805f9b34fb"
    
    private var isFirstAppear = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SLBleManager.shared.setUp()
        bleStatusLabel.backgroundColor = UIColor(displayP3Red: 0, green: 84/255.0, blue: 166/255.0, alpha: 0.4)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isFirstAppear else { return }
        isFirstAppear = false
        do {
            try SLConnectivityManager.shared.startScanDevices { [weak self] isScanning in
                self?.log(msg: "ble scan did \(isScanning ? "started" : "stopped")")
            } filter: { peripheral, advertisementData, rssi in
                if let services = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID], !services.isEmpty {
                    for uuid in services {
                        let uuidString = uuid.uuidString
                        if uuidString.hasPrefix("A6DDE9") && uuidString.contains("-") {
                            print("uuidString = \(uuidString)")
                            let components = uuid.uuidString.components(separatedBy: "-")
//                            if components.count == 5 {
//                                let
//                                let mac = components[4]
//                                let port = components[3]
//                            }
                        }
                    }
                    return true
                } else {
                    return false
                }
            } devicesUpdated: { array in
                
            }
        } catch {
            
        }
    }
    
    private func log(msg: String) {
        print("\n\(msg)\n")
    }
    
    deinit {
        log(msg: "\(self) deinit")
    }
}
