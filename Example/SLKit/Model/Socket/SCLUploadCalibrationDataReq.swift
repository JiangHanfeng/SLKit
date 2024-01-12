//
//  SCLUploadCalibrationDataReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

/// 上传校准数据
struct SCLUploadCalibrationDataReq : SCLSocketConetent {
    var cmd: SCLCmd = .uploadCalibrationData
    let data: String
    
    init() {
        cmd = .uploadCalibrationData
        data = ""
    }
    
    init(data: String) {
        self.data = data
    }
}
