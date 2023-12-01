//
//  SLBleScanTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/11/6.
//

import Foundation
import CoreBluetooth

public typealias SLBleScanStateUpdateCallback = ((_ isScanning: Bool) -> Void)
public typealias SLPeripheralDiscoveredCallback = (( _ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ rssi: NSNumber) -> Void)

struct SLBleScanHandler {
    var scanStateUpdated: SLBleScanStateUpdateCallback
    var peripheralDiscovered: SLPeripheralDiscoveredCallback
}

open class SLBleScanTask {
    var scanStateCallback: SLBleScanStateUpdateCallback
    var peripheralDiscoveredCallback: SLPeripheralDiscoveredCallback

    public init(scanStateCallback: @escaping SLBleScanStateUpdateCallback, peripheralDiscoveredCallback: @escaping SLPeripheralDiscoveredCallback) {
        self.scanStateCallback = scanStateCallback
        self.peripheralDiscoveredCallback = peripheralDiscoveredCallback
    }
    
    open func resume() throws {
        let a = unsafeBitCast(self, to: Int.self)
        print("a = \(a)")
        do {
            try SLBleManager.shared.startScan(task: self)
        } catch let e {
            throw e
        }
    }
}
