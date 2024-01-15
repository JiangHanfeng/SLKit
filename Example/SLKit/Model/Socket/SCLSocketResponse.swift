//
//  SCLSocketResponse.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLSocketResponse<T: SCLSocketConetent>: SLSocketDataMapper {
    var id: String = ""
    var data: Data? = nil
    
    var state: Int = -1
    var msg: String = ""
    var dev_mac: String = ""
    
    var content: T? = nil
    
    init(data: Data) {
        self.data = data
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any] else {
            return
        }
        let stateRange = 0...1
        if
            let taskId = json["taskId"] as? String,
            !taskId.isEmpty,
            let state = json["state"] as? Int,
            stateRange.contains(state)
        {
            let msg = json["msg"] as? String
            let dev_mac = json["dev_mac"] as? String
            self.id = taskId
            self.state = state
            self.msg = msg ?? ""
            self.dev_mac = dev_mac ?? ""
            self.content = T.deserialize(from: json)
        }
    }
}
