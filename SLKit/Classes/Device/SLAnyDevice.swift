//
//  SLDeviceFactory.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/11/24.
//

import Foundation
import CoreBluetooth
 
public final class SLAnyDevice<T: SLBaseDevice> {
    
    public typealias DeviceType = T
    
    public func build(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) -> T? {
        return _build(peripheral, advertisementData, rssi)
    }
    
    private let _build: ((CBPeripheral, [String : Any], NSNumber) -> T?)
    
    public init<Base: SLDeviceBuilder>(base: Base.Type) where Base.Device == T {
        self._build = base.build
    }
}
