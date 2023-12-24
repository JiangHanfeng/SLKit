//
//  SLResult.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/22.
//

import Foundation

public enum SLResult<T, E: Error> {
    case success(_ value : T)
    case failure(_ error: E)
}
