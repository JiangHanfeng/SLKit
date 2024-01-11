//
//  SLSocket.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/29.
//

import Foundation
import CocoaAsyncSocket

//public protocol SLSocketDataMapper {
//    init(data: Data) throws
//}

public typealias SLSocketDataCallback = ((Data) -> Void)

public struct SLSocketHeartbeatRule {
    public let interval: UInt
    public let timeout: UInt
    public let requestData: Data
    public let responseData: Data
    
    public init(interval: UInt, timeout: UInt, requestData: Data, responseData: Data) {
        self.interval = interval
        self.timeout = timeout
        self.requestData = requestData
        self.responseData = responseData
    }
}
