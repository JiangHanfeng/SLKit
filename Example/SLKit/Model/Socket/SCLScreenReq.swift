//
//  SCLScreenReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

struct SCLScreenReq : SCLSocketConetent {
    init() {
        ip = ""
        port1 = 0
        port2 = 0
        port3 = 0
    }
    
    init(ip: String, port1: UInt16, port2: UInt16, port3: UInt16) {
        self.ip = ip
        self.port1 = port1
        self.port2 = port2
        self.port3 = port3
    }
    
    var cmd: SCLCmd = .requestScreen
    var ip: String
    var port1: UInt16
    var port2: UInt16
    var port3: UInt16
}
