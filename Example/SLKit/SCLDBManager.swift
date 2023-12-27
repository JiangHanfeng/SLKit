//
//  SCLDBManager.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

class SCLDBManager {
    private static let kSCLPairedMacAddress = "kSCLPairedMacAddress"
    
    static func getPairedMacAddresses() -> [String] {
        return UserDefaults.standard.array(forKey: kSCLPairedMacAddress) as? [String] ?? []
    }
    
    static func add(pairedMacAddress: String) -> Bool {
        var arr = getPairedMacAddresses()
        arr.append(pairedMacAddress)
        UserDefaults.standard.setValue(arr, forKey: kSCLPairedMacAddress)
        return UserDefaults.standard.synchronize()
    }
    
    static func remove(pairedMacAddress: String) -> Bool {
        var arr = getPairedMacAddresses()
        arr.removeAll { item in
            item.elementsEqual(pairedMacAddress)
        }
        UserDefaults.standard.setValue(arr, forKey: kSCLPairedMacAddress)
        return UserDefaults.standard.synchronize()
    }
}

//import RealmSwift
//
//class SCLDBManager: NSObject {
//    public var realm: Realm!
//    
//    override init() {
//        do {
//            realm = try Realm(name: "main")
//        } catch let e {
//            print("打开realm数据库出错：\n\(e.localizedDescription)")
//        }
//    }
//    
//    static func update(realmVersion: UInt64) {
//        let config = Realm.Configuration(
//            schemaVersion: realmVersion) { migration, oldSchemaVersion in }
//        Realm.Configuration.defaultConfiguration = config
//    }
//}
//
//extension Realm {
//    init(name: String) throws {
//        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
//                                                          .userDomainMask,
//                                                          true).first!
//        let dbPath = docPath + "/db/" + name
//        if !FileManager.default.fileExists(atPath: dbPath) {
//            try FileManager.default.createDirectory(atPath: dbPath,
//                                                    withIntermediateDirectories: true,
//                                                    attributes: nil)
//        }
//        let url = URL(string: dbPath + "/" + name + ".realm")
//        try self.init(fileURL: url!)
//    }
//}
//
//extension UIApplication {
//    var buildVersion: UInt64 {
//        let buildVersion = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
//        return UInt64(buildVersion) ?? 1
//    }
//}
