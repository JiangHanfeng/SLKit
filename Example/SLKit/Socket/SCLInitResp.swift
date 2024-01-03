//
//  SCLInitResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLInitResp : SLSocketResponse {
    var id: String
    
    var data: Data?
    
    var cmd: Int
    var state: Int
    
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
                stateRange.contains(state)
            {
                self.cmd = cmd
                self.id = taskId
                self.state = state
            } else {
                throw NSError(domain: NSErrorDomain(string: "无法解析初始化平台响应") as String, code: -999, userInfo: [NSLocalizedDescriptionKey:"转换SCLTCPSocketResponse失败"])
            }
        } catch let e {
            throw e
        }
    }
}
