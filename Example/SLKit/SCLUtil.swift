//
//  SCLUtils.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/21.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import KeychainAccess

struct SCLUtil {
    static let KeychainService = Bundle.main.bundleIdentifier ?? "com.igrs.superconnectlite"
    static let DeviceIdentifierForVendor = UIDevice.current.identifierForVendor?.uuidString
    static let UUID_KEY:String = "UUID_KEY"
    static func getUUID() -> String {
        let keychain = Keychain(service: KeychainService)
        var uuid:String = ""
        do {
            uuid = try keychain.get(UUID_KEY) ?? ""
        }
        catch let error {
            print("keychain获取设备uuid出错：\n\(error.localizedDescription)")
        }
        if uuid.isEmpty {
            uuid = DeviceIdentifierForVendor ?? UUID().uuidString
            do {
                try keychain.set(uuid, key: UUID_KEY)
            }
            catch let error {
                print("keychain保存设备uuid出错：\n\(error.localizedDescription)")
            }
        }
        print("设备uuid： \(uuid)")
        return uuid
    }
}
