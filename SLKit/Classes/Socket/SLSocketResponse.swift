//
//  SLSocketResponse.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/26.
//

import Foundation

public protocol SLSocketResponse: SLSocketSessionItem {
    init(data: Data) throws
}
