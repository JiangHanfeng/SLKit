//
//  SLPeripheral.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/14.
//

import Foundation
import CoreBluetooth

struct SLPeripheral {
    var peripheral: CBPeripheral
    var advertisementData: [String : Any]
    var rssi: NSNumber
}
