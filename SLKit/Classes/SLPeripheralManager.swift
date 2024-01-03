//
//  SLPeripheralManager.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/29.
//

import Foundation
import CoreBluetooth

class SLPeripheralManager : NSObject {
    private var state = CBManagerState.unknown
    private var manager: CBPeripheralManager!
    private var stateUpdatedHandler: SLBleStateUpdatedHandler?
    private override init() {}
    
    convenience init(queue: DispatchQueue, stateUpdatedHandler: SLBleStateUpdatedHandler? = nil) {
        self.init()
        self.stateUpdatedHandler = stateUpdatedHandler
        self.manager = CBPeripheralManager(delegate: self, queue: queue)
    }
    
    public func available() -> Bool {
        return manager.state == .poweredOn
    }
    
    func startAdvertising(_ advertisementData: [String : Any]?) throws {
        guard manager.state == .poweredOn else {
            throw SLError.bleNotPowerOn
        }
//        var sendBytes = Array(repeating: [0], count: 21).flatMap {$0}
//        var bytes = Array(repeating: UInt8(0), count: 21)
//        var index = 0
//        data[0..<(data.count > 20 ? 20 : data.count - 1)].withUnsafeBytes { pointer in
//            if let uint8Value = pointer.baseAddress?.load(as: UInt8.self) {
//                bytes[index] = uint8Value
//                index += 1
//            }
//        }
//        let advertisementData = Data(bytes: bytes)
        manager.startAdvertising(advertisementData)
    }
    
    func stopAdvertising() {
        manager.stopAdvertising()
    }
}

extension SLPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if state != peripheral.state {
            state = peripheral.state
            stateUpdatedHandler?.handle(state)
        }
    }
}
