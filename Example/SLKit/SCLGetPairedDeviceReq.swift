//
//  SCLGetPairedDeviceReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/27.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

struct SCLGetPairedDeviceReq: SCLTCPSocketModel {
    var cmd: SCLTCPCmd = .getPairedDevices
}