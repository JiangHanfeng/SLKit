//
//  SCLQRResult.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/21.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import HandyJSON

struct SCLQRResult : HandyJSON {
    var `protocol` = ""
    var deviceType = ""
    var deviceName = ""
    var deviceModel = ""
    var bleName = ""
    var deviceMac = ""
    var deviceSn = ""
    var ip = ""
    var port = ""
    var fileControlPort = ""
    var fileDataPort = ""
    var versionName = ""
    var versionCode = ""
    var key = ""
    var timestamp = ""
    var validity = ""
    
    var available: Bool {
        return self.protocol.elementsEqual("free_style")
    }
}
