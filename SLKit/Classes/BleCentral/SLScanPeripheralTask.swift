//
//  SLScanPeripheralTask.swift
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

public class SLScanPeripheralTask: NSObject, SLTask {
    
    private static let queue = DispatchQueue(label: "com.slkit.scan_peripheral")
    
    typealias Progress = SLPeripheral
    
    typealias Exception = SLError
    
    typealias Result = Void
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: Self.queue)
    }
    
    deinit {
        print("\(self) deinit")
    }
    
    private lazy var address: Int = {
        return unsafeBitCast(self, to: Int.self)
    }()
    
    var id: Int {
        return address
    }
    
    private var centralManager: CBCentralManager!
    private var services: [CBUUID]?
    private var shouldStartScan = false
    private var isScanning = false
    
    var exceptionHandler: ((SLError) -> Void)?
    
    var discoveredPeripheralHandler: ((SLPeripheral) -> Void)?
    
    internal func start() {
        SLCentralManager.shared.startScanTask(self)
    }
    
    func exception(e: SLError) {
        exceptionHandler?(e)
    }
    
    func update(progress: SLPeripheral) {
        discoveredPeripheralHandler?(progress)
    }
    
    func completed(result: Void) {
        
    }
    
    func terminate() {
//        SLCentralManager.shared.stopScanTask(self)
        shouldStartScan = false
        isScanning = false
        centralManager.stopScan()
        centralManager = nil
    }
    
    public static func == (lhs: SLScanPeripheralTask, rhs: SLScanPeripheralTask) -> Bool {
        return lhs.id == rhs.id
    }
    
    class func stop(with id: Int) {
        SLCentralManager.shared.stopScanTask(id: id)
    }
    
    func start(with services: [CBUUID]? = nil) {
        self.services = services
        shouldStartScan = true
        isScanning = false
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: services)
        } else {
            centralManager = nil
            centralManager = CBCentralManager(delegate: self, queue: Self.queue)
        }
    }
}

extension SLScanPeripheralTask : CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            if !isScanning && shouldStartScan || isScanning {
                exceptionHandler?(SLError.bleNotPowerOn)
            }
        } else if shouldStartScan {
            shouldStartScan = false
            isScanning = true
            centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripheralHandler?(SLPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI))
    }
}
