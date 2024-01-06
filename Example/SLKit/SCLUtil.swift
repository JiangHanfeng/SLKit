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
    static let DEVICE_NAME_KEY : String = "DEVICE_NAME_KEY"
    static let FIRST_LAUNCH_KEY : String = "FIRST_LAUNCH_KEY"
    static let FIRST_AIR_PLAY_KEY : String = "FIRST_AIR_PLAY_KEY"
    static let CALIBRATION_DATA_KEY : String = "CALIBRATION_DATA_KEY"
    
    static func getUUID() -> String {
        var uuid = getStringValue(for: UUID_KEY, description: "设备uuid") ?? ""
        if uuid.isEmpty {
            uuid = DeviceIdentifierForVendor ?? UUID().uuidString
            _ = set(stringValue: uuid, for: UUID_KEY, description: "设备uuid")
        }
        return uuid
    }
    
    static func getDeviceId() -> String {
        return getTempMac().split(separator: ":").joined()
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
//        return getStringValue(for: BT_MAC_KEY, description: "设备蓝牙mac地址")
        return UserDefaults.standard.string(forKey: BT_MAC_KEY)
    }
    
    static func setBTMac(_ mac: String?) -> Bool {
//        return set(stringValue: mac, for: BT_MAC_KEY, description: "设备蓝牙mac地址")
        UserDefaults.standard.set(mac, forKey: BT_MAC_KEY)
        return UserDefaults.standard.synchronize()
    }
    
    static func getDeviceMac() -> String {
        if let btMac = getBTMac(), !btMac.isEmpty {
            return btMac
        }
        return getTempMac()
    }
    
    static func getDeviceName() -> String {
        return getStringValue(for: DEVICE_NAME_KEY) ?? UIDevice.current.name
    }
    
    static func setDeviceName(_ name: String) -> Bool {
        return set(stringValue: name, for: DEVICE_NAME_KEY, description: "设备名称")
    }
    
    static func isFirstLaunch() -> Bool {
        let firstLaunch = UserDefaults.standard.string(forKey: FIRST_LAUNCH_KEY)
        return firstLaunch == nil
    }
    
    static func markNotFirstLaunch() {
        UserDefaults.standard.setValue("0", forKey: FIRST_LAUNCH_KEY)
        UserDefaults.standard.synchronize()
    }
    
    static func isFirstAirPlay() -> Bool {
        return UserDefaults.standard.bool(forKey: FIRST_AIR_PLAY_KEY)
    }
    
    static func setFirstAirPlay(_ value: Bool) {
        UserDefaults.standard.setValue(value, forKey: FIRST_AIR_PLAY_KEY)
        UserDefaults.standard.synchronize()
    }
    
    // 获取校准数据
    static func getCalibrationData() -> String? {
        return UserDefaults.standard.string(forKey: CALIBRATION_DATA_KEY)
    }
    
    // 保存校准数据
    static func setCalibrationData(_ value: String?) -> Bool {
        UserDefaults.standard.setValue(value, forKey: CALIBRATION_DATA_KEY)
        return UserDefaults.standard.synchronize()
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
