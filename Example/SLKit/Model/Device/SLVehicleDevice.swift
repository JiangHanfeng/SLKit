//
//  SLVehicleDevice.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/6.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SLKit
import CoreBluetooth

class SLVehicleDevice {
    var blePeripheral: CBPeripheral
    var deviceMac: [UInt8]
    var deviceName: String
    var ssid: String
    var ip: String
    var port: Int
    var freeCount: Int
    
    init(blePeripheral: CBPeripheral, mac: [UInt8], name: String, ssid: String, ip: String, port: Int, freeCount: Int) {
        self.blePeripheral = blePeripheral
        self.deviceMac = mac
        self.deviceName = name
        self.ssid = ssid
        self.ip = ip
        self.port = port
        self.freeCount = freeCount
    }
}

extension SLVehicleDevice: SLBaseDevice {
    static func == (lhs: SLVehicleDevice, rhs: SLVehicleDevice) -> Bool {
        return lhs.blePeripheral.name ?? "" == rhs.blePeripheral.name ?? ""
            &&
        lhs.deviceMac == rhs.deviceMac
        &&
        lhs.deviceName == rhs.deviceName
        &&
        lhs.ssid == rhs.ssid
        &&
        lhs.ip == rhs.ip
        &&
        lhs.port == rhs.port
        &&
        lhs.freeCount == rhs.freeCount
    }
    
    var type: SLKit.SLDeviceType {
        return .vehicle(ssid: ssid, ip: ip, port: port, freeCount: freeCount)
    }
    
    var peripheral: CBPeripheral {
        return blePeripheral
    }
    
    var name: String {
        return deviceName
    }
    
    var mac: [UInt8] {
        return deviceMac
    }
}
