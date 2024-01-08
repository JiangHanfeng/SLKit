//
//  SCLPairVerificationReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/28.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SLKit
import HandyJSON

struct SCLPairVerificationReq : SLSocketRequest, HandyJSON {
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
        cmd = .requestPairVerification
        mac = ""
        deviceName = ""
    }
    
    var cmd: SCLCmd = .requestPairVerification
    
    init(device: SCLPCPairedDevice) {
        self.mac = device.mac
        self.deviceName = device.deviceName
    }
    
    let taskId = SCLUtil.getTempMac() + "_\(Date().timeIntervalSince1970)"
    let dev_id = SCLUtil.getTempMac().split(separator: ":").joined()
    let mac : String
    let deviceName : String
    let os = 1
    let version = Int(((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0")) ?? 0
    let dbg_info = "bug"
}
