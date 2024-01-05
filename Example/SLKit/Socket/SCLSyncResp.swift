//
//  SCLSyncResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLSyncResp : SLSocketDataMapper {
    var id: String = ""
    var data: Data? = nil
    
    var cmd: Int = SCLCmd.syncConnection.rawValue
    var state: Int = -1
    
    init(data: Data) {
        self.data = data
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any], let dict = json else {
            return
        }
        let stateRange = 0...1
        if
            let taskId = dict["taskId"] as? String,
            !taskId.isEmpty,
            let cmd = dict["cmd"] as? Int,
            let state = dict["state"] as? Int,
            stateRange.contains(state)
        {
            self.cmd = cmd
            self.id = taskId
            self.state = state
        }
    }
}
