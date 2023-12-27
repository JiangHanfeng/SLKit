//
//  SCLTCPSocketRequest.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import HandyJSON
import SLKit

enum SCLTCPCmd: Int, HandyJSONEnum {
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
    case getPairedDevices = 30
    case requestPair = 201
    case requestScreen = 203
    case requestFileTransfer = 204
}

protocol SCLTCPSocketModel : HandyJSON {
    var cmd: SCLTCPCmd { get }
}

struct SCLTCPSocketRequest<T: SCLTCPSocketModel> {

    let taskId = (UIDevice.current.identifierForVendor?.uuidString ?? "") + "_\(Date().timeIntervalSince1970)"
    let dev_id = UIDevice.current.identifierForVendor?.uuidString ?? ""
    let dev_mac = UIDevice.current.identifierForVendor?.uuidString ?? ""
    let deviceName = UIDevice.current.name
    let os = 1
    let version = Int(((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0")) ?? 0
    let model: T
    
    init(model: T) {
        self.model = model
    }
}

extension SCLTCPSocketRequest: SLSocketSessionItem {
    var id: String {
        return taskId
    }
    
    var data: Data? {
        guard var json = model.toJSON() else {
            return nil
        }
        json.updateValue(taskId, forKey: "taskId")
        json.updateValue(dev_id, forKey: "dev_id")
        json.updateValue(dev_mac, forKey: "dev_mac")
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
