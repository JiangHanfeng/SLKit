//
//  SCLScreenResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLScreenResp : SLSocketResponse {
    var id: String
    
    var data: Data?
    
    var cmd: Int
    var state: Int
    var ip: String
    var port1: UInt16
    var port2: UInt16
    var port3: UInt16
    
    init(data: Data) throws {
        self.data = data
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
            let stateRange = 0...1
            if
                let taskId = json?["taskId"] as? String,
                !taskId.isEmpty,
                let cmd = json?["cmd"] as? Int,
                let state = json?["state"] as? Int,
                stateRange.contains(state),
                let ip = json?["ip"] as? String,
                !ip.isEmpty,
                let port1 = json?["port1"] as? UInt16,
                let port2 = json?["port2"] as? UInt16,
                port2 > 0,
                let port3 = json?["port3"] as? UInt16,
                port3 > 0
            {
                self.cmd = cmd
                self.id = taskId
                self.state = state
                self.ip = ip
                self.port1 = port1
                self.port2 = port2
                self.port3 = port3
            } else {
                throw NSError(domain: NSErrorDomain(string: "无法解析投屏响应") as String, code: -999, userInfo: [NSLocalizedDescriptionKey:"转换SCLTCPSocketResponse失败"])
            }
        } catch let e {
            throw e
        }
    }
}
