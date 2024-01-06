//
//  SCLSocketLoginReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import HandyJSON
import SLKit

struct SCLSocketLoginReq {
    let cmd = 0
    let dev_id = SCLUtil.getDeviceId()
    let dev_mac = SCLUtil.getBTMac() ?? SCLUtil.getTempMac().split(separator: ":").joined()
    let deviceName = UIDevice.current.name
    let os = 1
    let version = Int(((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0")) ?? 0
    var retry: Bool
}

extension SCLSocketLoginReq: SLSocketRequest {
    var type: SLSocketSessionItemType {
        return .systemMessage
    }
    
    var id: String {
        return "0"
    }
    
    var data: Data? {
        var json: [String : Any] = [:]
        json["cmd"] = 0
        json["dev_id"] = dev_id
        json["mac"] = dev_mac
        json["deviceName"] = deviceName
        json["os"] = 1
        json["version"] = version
        json["retry"] = retry ? 1 : 0
//        guard let json = self.toJSON() else {
//            return nil
//        }
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

