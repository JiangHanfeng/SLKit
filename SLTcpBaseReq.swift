//
//  SLTcpBaseReq.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/22.
//

import Foundation
import HandyJSON

enum SLTCPCmd: Int, HandyJSONEnum {
    case login = 0
    case initPlatform = 1
    case end = 5
    case requestCalibration = 10
    case submitCalibrationData = 11
    case screenLocked = 13
    case updateBrightness = 14
    case updateUIOrientation = 15
    case syncMovePoint = 17
    case startAirplay = 20
    case hidConnected = 21
    case airplayUpdated = 23
    case requestPair = 201
    case requestScreen = 203
    case requestFileTransfer = 204
}
