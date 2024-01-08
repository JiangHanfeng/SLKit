//
//  SCLInitReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import SLKit
import HandyJSON

struct SCLInitReq : SLSocketRequest, HandyJSON {
    init() {
        mac = ""
    }
    
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
    
    let cmd: SCLCmd = .initPlatform
    
    let saving = 0
    let width = Int(UIScreen.main.bounds.width)
    let height = Int(UIScreen.main.bounds.height)
    let scale = Int(UIScreen.main.scale)
    let brightness = Int(UIScreen.main.brightness * 100)
    let distanceX = Int(UIDevice.safeDistanceTop())
    let distanceY = Int(UIDevice.safeDistanceTop())
    let hasPassword = 0
    let isHomeKey = false
    
    let taskId = SCLUtil.getTempMac() + "_\(Date().timeIntervalSince1970)"
    let dev_id : String = SCLUtil.getTempMac().split(separator: ":").joined()
    let mac : String
    let deviceName = UIDevice.current.name
    let os = 1
    let version = Int(((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0")) ?? 0
    let dbg_info = "bug"
    
    init(mac: String) {
        self.mac = mac
    }
}
