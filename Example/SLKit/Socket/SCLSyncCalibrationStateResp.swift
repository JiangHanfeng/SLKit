//
//  SCLSyncCalibrationStateResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLSyncCalibrationStateResp: SLSocketDataMapper {
    var id: String
    
    var data: Data?
    
    var state: Int
    
    init(data: Data) {
        self.data = data
        if 
            let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any],
            let dict = json, let cmd = dict["cmd"] as? Int,
            let state = dict["state"] as? Int{
            self.id = "\(cmd)"
            self.state = state
        } else {
            self.id = ""
            self.state = -1
        }
    }
}
