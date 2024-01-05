//
//  SCLSyncReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

struct SCLSyncReq : SCLSocketConetent {
    init() {
        cmd = .syncConnection
        deviceId = ""
        deviceName = ""
        ip = ""
        port1 = 0
        port2 = 0
        port3 = 0
    }
    
    var cmd: SCLCmd = .syncConnection
    
    let deviceName: String
    let deviceId: String
    let ip: String
    let port1: UInt16
    let port2: UInt16
    let port3: UInt16
    
    init(deviceName: String, deviceId: String, ip: String, port1: UInt16, port2: UInt16, port3: UInt16) {
        self.deviceName = deviceName
        self.deviceId = deviceId
        self.ip = ip
        self.port1 = port1
        self.port2 = port2
        self.port3 = port3
    }
}
