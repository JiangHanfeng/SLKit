//
//  SLTCPSocketSessionItem.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/26.
//

import Foundation

public protocol SLTCPSocketSessionItem {
    var id: String { get }
    var data: Data? { get }
}
