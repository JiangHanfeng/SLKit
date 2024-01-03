//
//  SCLInitReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

struct SCLInitReq : SCLSocketConetent {
    var cmd: SCLCmd = .initPlatform
    
    let saving = 0
    let width = Int(UIScreen.main.bounds.width)
    let height = Int(UIScreen.main.bounds.height)
    let scale = Int(UIScreen.main.scale)
    let brightness = Int(UIScreen.main.brightness * 100)
    let distanceX = Int(UIDevice.safeDistanceTop())
    let distanceY = Int(UIDevice.safeDistanceTop())
    let hasPassword = 0
    let isHomeKey = false
}
