//
//  SLVehicleDeviceBuilder.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import SLKit
import CoreBluetooth

class SLVehicleDeviceBuilder: SLDeviceBuilder {
    typealias DeviceType = SLVehicleDevice
    
    static func build(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) -> SLVehicleDevice? {
        return nil
    }
}
