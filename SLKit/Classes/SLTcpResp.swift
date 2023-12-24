//
//  SLTcpResp.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/22.
//

import Foundation
import HandyJSON

struct SLTcpResp: HandyJSON {
    let cmd: Int
    
    init() {
        self.cmd = -1
    }
    
    init(cmd: Int) {
        self.cmd = cmd
    }
}
