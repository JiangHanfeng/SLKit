//
//  SLBleServiceDiscoverTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/12.
//

import Foundation
import CoreBluetooth

public class SLBleServiceDiscoverTask: Equatable {
    public static func == (lhs: SLBleServiceDiscoverTask, rhs: SLBleServiceDiscoverTask) -> Bool {
        return lhs.peripheral == rhs.peripheral
    }
    
    var peripheral: CBPeripheral
    var started: (() -> Void)?
    var completion: ((_ services: [CBService], _ error: Error?) -> Void)?
    
    public init(peripheral: CBPeripheral, started: (() -> Void)? = nil, completion: ((_: [CBService], _: Error?) -> Void)? = nil) {
        self.peripheral = peripheral
        self.started = started
        self.completion = completion
    }
    
    public func start() throws {
        do {
            try SLBleManager.shared.startDiscoverServices(self)
        } catch let e {
            throw e
        }
    }
}
