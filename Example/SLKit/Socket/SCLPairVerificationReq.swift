//
//  SCLPairVerificationReq.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/28.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

struct SCLPairVerificationReq : SCLSocketConetent {    
    var cmd: SCLCmd = .requestPairVerification
    var device = SCLPCPairedDevice()
}
