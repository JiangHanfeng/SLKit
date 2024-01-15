//
//  SCLInitResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLInitResp : SLSocketDataMapper {
    var id: String = ""
    var data: Data?
    
    var cmd: Int = SCLCmd.initPlatform.rawValue
    var state: Int = -1
    
    init(data: Data) {
        self.data = data
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any] else {
            return
        }
        let stateRange = 0...1
        if
            let taskId = json["taskId"] as? String,
            !taskId.isEmpty,
            let cmd = json["cmd"] as? Int,
            let state = json["state"] as? Int,
            stateRange.contains(state)
        {
            self.cmd = cmd
            self.id = taskId
            self.state = state
        }
    }
}
