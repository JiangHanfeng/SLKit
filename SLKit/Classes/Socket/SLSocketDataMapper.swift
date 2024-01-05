//
//  SLSocketDataMapper.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/26.
//

import Foundation

public protocol SLSocketDataMapper: SLSocketSessionItem {
    init(data: Data)
}
