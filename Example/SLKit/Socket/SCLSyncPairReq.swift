//
//  SCLSyncPairReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

struct SCLSyncPairReq : SCLSocketConetent {
    init() {
        cmd = .syncPairSuccess
        state = 0
    }
    
    var cmd: SCLCmd = .syncPairSuccess
    var device: SCLPCPairedDevice = SCLPCPairedDevice()
    var state: Int = 0
    let os = 1
    
    init(device: SCLPCPairedDevice, state: Int) {
        self.device = device
        self.state = state
    }
}
