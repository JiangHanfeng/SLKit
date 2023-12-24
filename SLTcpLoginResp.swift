//
//  SLTcpLoginResp.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/22.
//

import Foundation
import HandyJSON

struct SLTcpLoginResp : HandyJSON {
    let state: Int
    let dev_mac: String
    let os: Int
    let version: String
    let dbg_info: String
    
    init(state: Int, dev_mac: String, os: Int, version: String, dbg_info: String) {
        self.state = state
        self.dev_mac = dev_mac
        self.os = os
        self.version = version
        self.dbg_info = dbg_info
    }
    
    init() {
        self.init(state: 0, dev_mac: "", os: 0, version: "", dbg_info: "")
    }
}
