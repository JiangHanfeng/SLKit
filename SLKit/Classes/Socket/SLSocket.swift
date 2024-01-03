//
//  SLSocket.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/29.
//

import Foundation
import CocoaAsyncSocket



public typealias SLSocketDataHandler = ((Data) -> Void)

public struct SLSocketHeartbeatRule {
    public let interval: UInt
    public let timeout: UInt
    public let requestValue: String
    public let reponseValue: String
    
    public init(interval: UInt, timeout: UInt, requestValue: String, reponseValue: String) {
        self.interval = interval
        self.timeout = timeout
        self.requestValue = requestValue
        self.reponseValue = reponseValue
    }
}
