//
//  SLInitPlatformReq.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/22.
//

import Foundation
import HandyJSON

struct SLInitPlatformReq : HandyJSON {
    let cmd = 1
    let os = 1
    let mac: String
    let dev_id: String
    let saving: Int
    let width: Int
    let height: Int
    let scale: Int
    let brightness: Int
    let distanceX: Int
    let distanceY: Int
    let hasPassword: Int
    let isHomeKey = 0
    let dbg_info = "bug"
    
    init(mac: String, dev_id: String, saving: Int, width: Int, height: Int, scale: Int, brightness: Int, distanceX: Int, distanceY: Int, hasPassword: Int) {
        self.mac = mac
        self.dev_id = dev_id
        self.saving = saving
        self.width = width
        self.height = height
        self.scale = scale
        self.brightness = brightness
        self.distanceX = distanceX
        self.distanceY = distanceY
        self.hasPassword = hasPassword
    }
    
    init() {
        self.init(mac: "", dev_id: "", saving: 0, width: 0, height: 0, scale: 0, brightness: 0, distanceX: 0, distanceY: 0, hasPassword: 0)
    }
}
