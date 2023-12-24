//
//  SLReadCharacteristicTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/12.
//

import Foundation
import CoreBluetooth

public class SLReadCharacteristicTask: Equatable {
    public static func == (lhs: SLReadCharacteristicTask, rhs: SLReadCharacteristicTask) -> Bool {
        return lhs.peripheral == rhs.peripheral && lhs.characteristic == rhs.characteristic
    }
    
    var peripheral: CBPeripheral
    var characteristic: CBCharacteristic
    var started: (() -> Void)?
    var completion: ((_ data: Data?, _ error: Error?) -> Void)?
    
    public init(peripheral: CBPeripheral, characteristic: CBCharacteristic, started: (() -> Void)? = nil, completion: ((_: Data?, _: Error?) -> Void)? = nil) {
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.started = started
        self.completion = completion
    }
    
    public func start() throws {
        do {
            try SLBleManager.shared.startReadCharacteristic(self)
        } catch let e {
            throw e
        }
    }
}
