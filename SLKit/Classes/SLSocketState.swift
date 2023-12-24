//
//  SLSocketState.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/19.
//

import Foundation

public enum SLSocketState {
    case initialized
    case connecting
    case connected(Data?)
}
