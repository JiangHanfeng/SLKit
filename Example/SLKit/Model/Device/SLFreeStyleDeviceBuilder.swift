//
//  SLFreeStyleDeviceBuilder.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SLKit
import CoreBluetooth

class SLFreeStyleDeviceBuilder: SLDeviceBuilder {
    static let service_uuid_prefix = "A6DDE8"
    
    static func build(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) -> SLFreeStyleDevice? {
        guard let name = peripheral.name, name.count > 0 else {
            return nil
        }
        return SLFreeStyleDevice(name: peripheral.name ?? "", mac: [], ip: [], port: 0, blePeripheral: peripheral)
        guard let uuids = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID], !uuids.isEmpty else {
            return nil
        }
        var device:SLFreeStyleDevice?
        for uuid in uuids {
            guard uuid.uuidString.starts(with: Self.service_uuid_prefix) else {
                continue
            }
            let components = uuid.uuidString.components(separatedBy: "-")
            guard components.count == 5 else {
                continue
            }
            let name = (advertisementData["kCBAdvDataLocalName"] as? String) ?? ""
            let mac = components.last!
            guard let macAddress = mac.hex2Mac(), macAddress.count == 6 else {
                continue
            }
            let ipStr = components[1] + components[2]
            let portStr = components[3]
            if !ipStr.elementsEqual("00000000") && !portStr.elementsEqual("0000") {
                if let ipV4Array = ipStr.hex2IpV4(), ipV4Array.count == 4, let port = portStr.hex2Port() {
                    device = SLFreeStyleDevice(name: name, mac: macAddress, ip: ipV4Array, port: port, blePeripheral: peripheral)
                    break
                } else {
                    device = SLFreeStyleDevice(name: name, mac: macAddress, ip: [], port: 0, blePeripheral: peripheral)
                    break
                }
            } else {
                device = SLFreeStyleDevice(name: name, mac: macAddress, ip: [], port: 0, blePeripheral: peripheral)
                break
            }
        }
        return device
    }
    
    typealias Device = SLFreeStyleDevice
}

