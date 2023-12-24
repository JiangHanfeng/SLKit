//
//  SLSocket.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/22.
//

import Foundation
import CocoaAsyncSocket

public class SLSocket: NSObject {
    
    enum Role {
        case server, client
    }
    
    enum State {
        case initilized
        case connecting
        case connected
        case disconnected
    }
    
    var host: String
    var port: UInt16
    var role: Role
    var state: State!
    
    init(host: String, port: UInt16, role: Role) {
        self.host = host
        self.port = port
        self.role = role
        self.state = .initilized
    }
}
