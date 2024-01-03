//
//  SCLGetPairedDeviceResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import HandyJSON

struct SCLPCPairedDevice : HandyJSON, Equatable {
    init() {
        deviceName = ""
        deviceMac = ""
    }
    
    let deviceName: String
    let deviceMac: String
}

struct SCLGetPairedDeviceResp : SCLSocketConetent {
    let cmd: SCLCmd
    let deviceList: [SCLPCPairedDevice]
    
    init() {
        self.cmd = .getPairedDevices
        self.deviceList = []
    }
}
