//
//  SCLSyncMovePointResp.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

struct SCLSyncMovePointResp: SLSocketDataMapper {
    var id: String
    
    var data: Data?
    
    init(data: Data) {
        self.data = data
        if
            let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any],
            let dict = json, let cmd = dict["cmd"] as? Int {
            self.id = "\(cmd)"
        } else {
            self.id = ""
        }
    }
}
