//
//  SCLSocketRequest.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import HandyJSON
import SLKit

enum SCLCmd: Int, HandyJSONEnum {
    case unknown = -1
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
    case stopAirplay = 25
    case syncConnection = 26 // tcp login成功后发送本条命令，参数为设备名
    case getPairedDevices = 30
    case requestPairVerification = 31
    case syncPairSuccess = 32
    case requestPair = 201
    case pairCompleted = 202
    case requestScreen = 203
    case requestFileTransfer = 204
}

protocol SCLSocketConetent : HandyJSON {
    var cmd: SCLCmd { get }
}

struct SCLSocketGenericContent: SCLSocketConetent {
    init() {
        cmd = .unknown
    }
    
    init(cmd: SCLCmd) {
        self.cmd = cmd
    }
    
    var cmd: SCLCmd
}

struct SCLSocketRequest<T: SCLSocketConetent> {
    let taskId = (UIDevice.current.identifierForVendor?.uuidString ?? "") + "_\(Date().timeIntervalSince1970)"
    let dev_id = SCLUtil.getDeviceMac().split(separator: ":").joined()
    let dev_mac = SCLUtil.getBTMac()?.split(separator: ":").joined() ?? SCLUtil.getDeviceMac().split(separator: ":").joined()
    let deviceName = UIDevice.current.name
    let os = 1
    let version = Int(((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0")) ?? 0
    let dbg_info = "bug"
    let content: T
    
    init(content: T) {
        self.content = content
    }
}

extension SCLSocketRequest: SLSocketRequest {
    var type: SLSocketSessionItemType {
        return .businessMessage
    }
    
    var id: String {
        return taskId
    }
    
    var data: Data? {
        guard var json = content.toJSON() else {
            return nil
        }
        json.updateValue(taskId, forKey: "taskId")
        json.updateValue(dev_id, forKey: "dev_id")
        json.updateValue(dev_mac, forKey: "mac")
        json.updateValue(deviceName, forKey: "deviceName")
        json.updateValue(os, forKey: "os")
        json.updateValue(version, forKey: "version")
        do {
            let data = try JSONSerialization.data(withJSONObject: json)
            if let string = String(data: data, encoding: .utf8) {
                return string.data(using: .utf8)
            }
            return nil
        } catch let error {
            SLLog.debug("SCLTCPSocketRequest转Data失败:\(error.localizedDescription)")
            return nil
        }
    }
}
