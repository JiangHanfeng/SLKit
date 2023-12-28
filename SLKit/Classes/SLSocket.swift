//
//  SLSocket.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/22.
//

import Foundation
import CocoaAsyncSocket

public struct SLSocketHeartbeatRule {
    public let interval: UInt
    public let timeout: UInt
    public let sendValue: String
    public let reponseValue: String
    
    public init(interval: UInt, timeout: UInt, sendValue: String, reponseValue: String) {
        self.interval = interval
        self.timeout = timeout
        self.sendValue = sendValue
        self.reponseValue = reponseValue
    }
}

public class SLSocket: NSObject {
    
    public enum Role {
        case server, client
    }
    
    public enum State {
        case initilized
        case connecting
        case connected
        case disconnectedUnexpected
    }
    
    var host: String
    var port: UInt16
    var role: Role
    var state: State!
    public let heartbeatRule: SLSocketHeartbeatRule?
    
    init(host: String, port: UInt16, role: Role, heartbeatRule: SLSocketHeartbeatRule? = nil) {
        self.host = host
        self.port = port
        self.role = role
        if let heartbeatRule {
            guard
                heartbeatRule.interval > 0,
                heartbeatRule.timeout > heartbeatRule.interval,
                !heartbeatRule.sendValue.isEmpty,
                !heartbeatRule.reponseValue.isEmpty else {
                fatalError("SLSocket heartbeat rule format incorrect!!!")
            }
        }
        self.heartbeatRule = heartbeatRule
        self.state = .initilized
    }
}
