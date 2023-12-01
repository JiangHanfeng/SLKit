//
//  SLError.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/11/7.
//

import Foundation

public enum SLError: Error, LocalizedError {
    case internalStateError(msg: String)
    case bleNotPowerOn
    
    public var errorDescription: String? {
        switch self {
        case .internalStateError(msg: let msg):
            return msg
        case .bleNotPowerOn:
            return "the CBManagerState isndevicet powerOn at this moment"
        }
    }
}
