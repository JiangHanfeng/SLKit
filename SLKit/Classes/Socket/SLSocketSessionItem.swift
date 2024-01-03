//
//  SLSocketSessionItem.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/26.
//

import Foundation

public enum SLSocketSessionItemType: UInt8 {
    case heartbeat = 0x00
    case systemMessage = 0x10
    case businessMessage = 0x11
}

public protocol SLSocketSessionItem {
    var id: String { get }
    var data: Data? { get }
}

public protocol SLSocketRequest : SLSocketSessionItem {
    var type: SLSocketSessionItemType { get }
}
