//
//  SCLSocketLoginResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLSocketLoginResp: SLSocketDataMapper {
    var id: String = ""
    var data: Data?
    
    var state: Int = SCLCmd.login.rawValue
    var msg: String = ""
    var dev_id: String = ""
    var dev_name: String = ""
    
    init(data: Data) {
        self.data = data
        var json: [String : Any]?
        do {
            json = try JSONSerialization.jsonObject(with: data) as? [String : Any]
        } catch let e {
            SLLog.debug("反序列化cmd0响应数据异常:\n\(e.localizedDescription)")
        }
        guard let json else {
            return
        }
        let stateRange = 0...1
        if
            let cmd = json["cmd"] as? Int,
            cmd == 0,
            let state = json["state"] as? Int,
            stateRange.contains(state),
            let dev_id = json["dev_id"] as? String,
            !dev_id.isEmpty,
            let dev_name = json["dev_name"] as? String
        {
            self.id = "0"
            self.state = state
            self.msg = state == 1 ? "登录成功" : "登录失败"
            self.dev_id = dev_id
            self.dev_name = dev_name
        }
    }
}
