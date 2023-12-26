//
//  SCLTCPLoginRequest.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

struct SCLTCPLoginModel : SCLTCPSocketModel {
    init() {
        self.cmd = .login
        self.code = -1
    }
    
    var cmd: SCLTCPCmd = .login
    var code: Int
    
    init(code: Int) {
        self.code = code
    }
}
