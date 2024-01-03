//
//  SCLUtils.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/21.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import KeychainAccess
import SLKit

struct SCLUtil {
    static let KeychainService = Bundle.main.bundleIdentifier ?? "com.igrs.superconnectlite"
    static let DeviceIdentifierForVendor = UIDevice.current.identifierForVendor?.uuidString
    static let UUID_KEY : String = "UUID_KEY"
    static let TEMP_MAC_KEY : String = "TEMP_MAC_KEY"
    static let BT_MAC_KEY : String = "BT_MAC_KEY"
    static func getUUID() -> String {
        var uuid = getStringValue(for: UUID_KEY, description: "设备uuid") ?? ""
        if uuid.isEmpty {
            uuid = DeviceIdentifierForVendor ?? UUID().uuidString
            _ = set(stringValue: uuid, for: UUID_KEY, description: "设备uuid")
        }
        return uuid
    }
    
    static func getTempMac() -> String {
        var mac = getStringValue(for: TEMP_MAC_KEY) ?? ""
        if mac.isEmpty {
            mac = SLKit.randomMacAddressString()
            _ = set(stringValue: mac, for: TEMP_MAC_KEY)
        }
        return mac
    }
    
    static func setTempMac(_ mac: String?) -> Bool {
        return set(stringValue: mac, for: TEMP_MAC_KEY)
    }
    
    static func getBTMac() -> String? {
        return getStringValue(for: BT_MAC_KEY, description: "设备蓝牙mac地址")
    }
    
    static func setBTMac(_ mac: String?) -> Bool {
        return set(stringValue: mac, for: BT_MAC_KEY, description: "设备蓝牙mac地址")
    }
    
    private static func getStringValue(for key: String, description: String? = nil) -> String? {
        let keychain = Keychain(service: KeychainService)
        var value: String?
        do {
            value = try keychain.get(key)
        } catch let error {
            if let description, description.count > 0 {
                print("keychain get string value for \(description) error:\n\(error.localizedDescription)\n")
            }
        }
        return value
    }
    
    private static func set(stringValue: String?, for key: String, description: String? = nil) -> Bool {
        let keychain = Keychain(service: KeychainService)
        do {
            if let stringValue {
                try keychain.set(stringValue, key: key)
            } else {
                try keychain.remove(key)
            }
            return true
        } catch let error {
            if let description, description.count > 0 {
                print("keychain set value for \(description) error:\n\(error.localizedDescription)\n")
            }
            return false
        }
    }
}
