//
//  SCLUploadCalibrationDataResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import HandyJSON

struct SCLUploadCalibrationDataResp : SCLSocketConetent {
    let cmd: SCLCmd
    let succ: Int
    
    init() {
        self.cmd = .getPairedDevices
        self.succ = 0
    }
}
