//
//  SCLSyncPairReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import HandyJSON
import SLKit

struct SCLSyncPairReq : SLSocketRequest, HandyJSON {
    var type: SLKit.SLSocketSessionItemType = .businessMessage
    
    var id: String {
        return taskId
    }
    
    var data: Data? {
        if let json = toJSON() {
            return try? JSONSerialization.data(withJSONObject: json)
        }
        return nil
    }
    
    init() {
        cmd = .syncPairSuccess
        mac = ""
        deviceName = ""
        state = -1
    }
    
    var cmd: SCLCmd = .syncPairSuccess
    
    init(device: SCLPCPairedDevice, pairResult: Bool) {
        self.mac = device.mac
        self.deviceName = device.deviceName
        self.state = pairResult ? 1 : 0
    }
    
    let taskId = SCLUtil.getTempMac() + "_\(Date().timeIntervalSince1970)"
    let dev_id = SCLUtil.getTempMac().split(separator: ":").joined()
    let mac : String
    let deviceName : String
    let os = 1
    let version = Int(((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0")) ?? 0
    let dbg_info = "bug"
    let state : Int
}

