//
//  SLDevice.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/4.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

//enum SLDeviceRole {
//    case client(UInt16, SLAcceptedSocket)
//    case server(SLSocketClient)
//}

//extension SLDeviceRole : Equatable {
//    public static func == (lhs: SLDeviceRole, rhs: SLDeviceRole) -> Bool {
//        switch lhs {
//        case .client(let port1, let sock1):
//            switch rhs {
//            case .client(let port2, let sock2):
//                return port1 == port2 && sock1 == sock2
//            case .server(_):
//                return false
//            }
//        case .server(let sock1):
//            switch rhs {
//            case .client(_, _):
//                return false
//            case .server(let sock2):
//                return sock1 == sock2
//            }
//        }
//    }
//}

@objcMembers class SLDevice : NSObject {
    let id: String
    let name: String
    let mac: String
    let bleName: String
    let localClient: SLSocketClient
    init(id: String, name: String, mac: String, bleName: String, localClient: SLSocketClient) {
        self.id = id
        self.name = name
        self.mac = mac
        self.bleName = bleName
        self.localClient = localClient
    }
    
    public static func == (lhs: SLDevice, rhs: SLDevice) -> Bool {
        return lhs.id.elementsEqual(rhs.id) && lhs.name.elementsEqual(rhs.name) && lhs.mac.elementsEqual(rhs.mac) && lhs.localClient == rhs.localClient
    }
    
    deinit {
        print("\(self) deinit")
    }
}
