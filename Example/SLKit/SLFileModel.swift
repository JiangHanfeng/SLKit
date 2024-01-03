//
//  SLFileModel.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

public enum SLFileType : Int {
    case unknown = 0
    case folder = 1
    case video = 2
    case image = 3
    case audio = 4
    case excel = 5
    case pdf = 6
    case word = 7
    case ppt = 8
    case zip = 9
    case txt = 10
}

@objcMembers public class SLFileModel : NSObject {
    var path: String = ""
    var name: String = ""
    var extensionName: String = ""
    var time: Int = 0
    
    var fullPath: String {
        return path + "/\(name).\(extensionName)"
    }
    
    public override init() {
        
    }
    
    init(path: String, name: String, extensionName: String, time: Int) {
        self.path = path
        self.name = name
        self.extensionName = extensionName
        self.time = time
    }
}
