//
//  SCLSyncAirplayStateReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import HandyJSON
import SLKit

struct SCLSyncAirplayStateReq : SLSocketRequest, HandyJSON {
    init() {
        type = .businessMessage
        cmd = SCLCmd.unknown
    }
    
    var type: SLKit.SLSocketSessionItemType = .businessMessage
    
    var id: String {
        return "\(cmd.rawValue)"
    }
    
    var data: Data? {
        if let json = toJSON() {
            return try? JSONSerialization.data(withJSONObject: json)
        }
        return nil
    }
    
    let cmd: SCLCmd
    
    init(cmd: SCLCmd) {
        self.cmd = cmd
    }
}
