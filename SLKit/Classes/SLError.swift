//
//  SLError.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/11/7.
//

import Foundation

public enum SLError: Error, LocalizedError {
    case internalStateError(String)
    case bleNotPowerOn
    case bleScanTimeout
    case bleConnectionTimeout
    case bleConnectionFailure(Error?)
    case bleDisconnected(Error?)
    case locationNotAllowed
    case socketWrongRole
    case socketWrongClientState
    case socketConnectionFailure(Error)
    case socketConnectionTimeout
    case socketDisconnectedHeartbeatTimeout
    case socketDisconnected(Error?)
    case socketSendFailureNotConnected
    case socketSendFailureEmptyData
    case socketSendFailureDataError
    case socketNotConnectedYet
    case socketDisconnectedWaitingForResponse
    case socketHasBeenReleased
    case socketWrongServerState
    case socketListenFailure(Error)
    case taskCanceled
    case taskTimeout
    
    public var errorDescription: String? {
        switch self {
        case .internalStateError(let msg):
            return msg
        case .bleNotPowerOn:
            return "the CBManagerState not powerOn at this moment"
        case .bleScanTimeout:
            return "scan ble peripheral out of time"
        case .bleConnectionTimeout:
            return "connect ble peripheral out of time"
        case .bleConnectionFailure(let error):
            return error != nil ? error!.localizedDescription : "ble connection failure"
        case .bleDisconnected(let error):
            return error != nil ? error!.localizedDescription : "ble disconnected"
        case .locationNotAllowed:
            return "未授予定位权限"
        case .socketWrongClientState:
            return "socket wrong state"
        case .socketConnectionFailure(let error):
            return error.localizedDescription
        case .socketConnectionTimeout:
            return "socket connect timeout"
        case .socketDisconnectedHeartbeatTimeout:
            return "socket disconnected because of heartbeat timeout"
        case .socketDisconnected(let error):
            return error != nil ? error!.localizedDescription : "socket disconnected"
        case .socketSendFailureNotConnected:
            return "send data failed because the socket hasn't been connected yet"
        case .socketSendFailureEmptyData:
            return "send data failed because the data can't be empty or nil"
        case .socketSendFailureDataError:
            return "send data failed because the string can't convert to Data"
        case .socketNotConnectedYet:
            return "socket hasn't been connected yet"
        case .socketDisconnectedWaitingForResponse:
            return "socket has disconected when waiting for the response"
        case .socketHasBeenReleased:
            return "socket has been released"
        case .socketWrongServerState:
            return "socket serve error state"
        case .socketWrongRole:
            return "socket wrong role"
        case .socketListenFailure(let error):
            return error.localizedDescription
        case .taskCanceled:
            return "任务已取消"
        case .taskTimeout:
            return "任务超时"
        }
    }
}
