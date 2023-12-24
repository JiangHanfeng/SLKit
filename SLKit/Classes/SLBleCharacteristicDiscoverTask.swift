//
//  SLBleCharacteristicDiscoverTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/12.
//

import Foundation
import CoreBluetooth

public class SLBleCharacteristicDiscoverTask {
    var peripheral: CBPeripheral
    var service: CBService
    var started: (() -> Void)?
    var completion: ((_ characteristics: [CBCharacteristic], _ error: Error?) -> Void)?
    
    public init(peripheral: CBPeripheral, service: CBService, started: (() -> Void)? = nil, completion: ((_: [CBCharacteristic], _: Error?) -> Void)? = nil) {
        self.peripheral = peripheral
        self.service = service
        self.started = started
        self.completion = completion
    }
    
    public func start() throws {
        do {
            try SLBleManager.shared.startDiscoverCharacterisics(self)
        } catch let e {
            throw e
        }
    }
}
