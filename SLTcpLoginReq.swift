//
//  SLTcpLoginReq.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/22.
//

import Foundation
import HandyJSON

struct SLTcpLoginReq: HandyJSON {
    init() {
        self.dev_mac = ""
        self.dev_id = ""
        self.version = ""
        self.retry = 0
    }
    
    let cmd = 0
    let os: Int = 1
    let dev_mac: String
    let dev_id: String
    let version: String
    let retry: Int
    let dbg_info = "bug"
    
    init(dev_mac: String, dev_id: String, version: String, retry: Int) {
        self.dev_mac = dev_mac
        self.dev_id = dev_id
        self.version = version
        self.retry = retry
    }
}
