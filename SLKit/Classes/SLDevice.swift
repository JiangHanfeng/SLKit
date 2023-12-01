//
//  SLDevice.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/11/24.
//

import Foundation
import CoreBluetooth
 
public class SLDevice {
    var peripheral: CBPeripheral
    var mac: String
    var ip_v4: String
    var port: Int
    init(peripheral: CBPeripheral, mac: String, ip_v4: String, port: Int) {
        self.peripheral = peripheral
        self.mac = mac
        self.ip_v4 = ip_v4
        self.port = port
    }
}
