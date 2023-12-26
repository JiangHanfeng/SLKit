//
//  SCLTCPSocketResponse.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLTCPSocketResponse: SLTCPSocketResponse {
    var id: String
    var data: Data?
    
    var state: Int
    var msg: String
    var dev_mac: String
    
    init(data: Data) throws {
        self.data = data
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
            let stateRange = 0...1
            if
                let taskId = json?["taskId"] as? String,
                !taskId.isEmpty,
                let state = json?["state"] as? Int,
                stateRange.contains(state),
                let msg = json?["msg"] as? String,
                let dev_mac = json?["dev_mac"] as? String,
                !dev_mac.isEmpty
            {
                self.id = taskId
                self.state = state
                self.msg = msg
                self.dev_mac = dev_mac
            } else {
                throw NSError(domain: NSErrorDomain(string: "failed to get taskId/state/msg/dev_mac") as String, code: -999, userInfo: [NSLocalizedDescriptionKey:"转换SCLTCPSocketResponse失败"])
            }
        } catch let e {
            throw e
        }
    }
    
}
