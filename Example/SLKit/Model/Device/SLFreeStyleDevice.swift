//
//  SLFreeStyleDevice.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/5.
//

import Foundation
import CoreBluetooth
import SLKit

@objcMembers class SLFreeStyleDevice : NSObject {
    private let blePeripheral: CBPeripheral
    private let deviceName: String
    private let deviceMac: [UInt8]
    let ip: [UInt8]
    let port: UInt16
    var key: Data?
    
    lazy var macString: String? = {
        guard deviceMac.count == 6 else {
            return nil
        }
        return deviceMac.map { uint8 in
            String(format: "%02X", uint8)
        }.joined(separator: ":")
    }()
    
    lazy var ipString: String? = {
        guard ip.count == 4 else {
            return nil
        }
        return ip.map { uint8 in
            "\(uint8)"
        }.joined(separator: ".")
    }()
    
    lazy var host: String? = {
        if let ipString, port > 0 {
            return ipString + ":" + "\(port)"
        }
        return nil
    }()
    
    init(name: String, mac: [UInt8], ip: [UInt8], port: UInt16, blePeripheral: CBPeripheral) {
        self.deviceName = name
        self.deviceMac = mac
        self.ip = ip
        self.port = port
        self.blePeripheral = blePeripheral
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard object is Self else {
            return false
        }
        let anotherOne = object as! Self
        return mac.elementsEqual(anotherOne.mac) && name.elementsEqual(anotherOne.name)
    }
}

extension SLFreeStyleDevice: SLBaseDevice {
    var type: SLDeviceType {
        return .freestyle(key: key)
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
