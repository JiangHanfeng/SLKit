//
//  SCLEndReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

struct SCLEndReq : SCLSocketConetent {
    init() {
        cmd = .end
        state = 0
    }
    
    var cmd: SCLCmd = .end
    
    let state: Int
    
    init(state: Int) {
        self.state = state
    }
}
