//
//  SCLSyncMovePointReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit
import HandyJSON

struct SCLSyncMovePointReq : SLSocketRequest, HandyJSON {
    init() {
        type = .businessMessage
        step = 0
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
    
    let cmd: SCLCmd = .syncMovePoint
    let step: Int
    
    init(step: Int) {
        self.step = step
    }
}
