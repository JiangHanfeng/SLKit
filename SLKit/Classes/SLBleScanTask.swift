//
//  SLBleScanTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/11/6.
//

import Foundation
import CoreBluetooth

public typealias SLPeripheralDiscoveredCallback = (( _ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ rssi: NSNumber) -> Void)

//public enum SLBleScanTaskDecision {
//    case keep
//    case interruppt
//}

public class SLBleScanTask: SLTask {
    
    typealias Progress = SLPeripheral
    
    typealias Exception = SLError
    
    typealias Result = Void
    
    var id: String {
        let address = unsafeBitCast(self, to: Int.self)
        return "\(address)"
    }
    
    let exceptionHandler: (SLError) -> Void
    
    let progressHandler: (SLPeripheral) -> Bool
    
    private var discoveredPeripherals: Array<SLPeripheral> = []
    
    private var shouldUpdate = true
    
    func start() {
        SLBleManager.shared.startScanTask(self)
    }
    
    func exception(e: SLError) {
        exceptionHandler(e)
    }
    
    func update(progress: SLPeripheral) {
        guard shouldUpdate else {
            terminate()
            return
        }
        shouldUpdate = progressHandler(progress)
        !shouldUpdate ? terminate() : nil
    }
    
    func completed(result: Void) {
        
    }
    
    func terminate() {
        SLBleManager.shared.stopScanTask(self)
    }
    
    public static func == (lhs: SLBleScanTask, rhs: SLBleScanTask) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(
        progressHandler: @escaping (SLPeripheral) -> Bool,
        exceptionHandler: @escaping (SLError) -> Void
    ) {
        self.progressHandler = progressHandler
        self.exceptionHandler = exceptionHandler
    }
    
    deinit {
        print("\(self) deinit")
    }
    
    class func stop(with id: String) {
        SLBleManager.shared.stopScanTask(id: id)
    }
}
