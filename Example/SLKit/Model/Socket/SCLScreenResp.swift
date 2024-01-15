//
//  SCLScreenResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLScreenResp : SLSocketDataMapper {
    var id: String = ""
    
    var data: Data?
    
    var cmd: Int = SCLCmd.requestScreen.rawValue
    var state: Int = -1
    var ip: String = ""
    var port1: UInt16 = 0
    var port2: UInt16 = 0
    var port3: UInt16 = 0
    
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
            stateRange.contains(state),
            let ip = json["ip"] as? String,
            !ip.isEmpty,
            let port1 = json["port1"] as? UInt16,
            let port2 = json["port2"] as? UInt16,
            port2 > 0,
            let port3 = json["port3"] as? UInt16,
            port3 > 0
        {
            self.cmd = cmd
            self.id = taskId
            self.state = state
            self.ip = ip
            self.port1 = port1
            self.port2 = port2
            self.port3 = port3
        }
    }
}
