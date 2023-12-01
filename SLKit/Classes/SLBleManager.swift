//
//  SLBleManager.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/11/3.
//

import Foundation
import CoreBluetooth

typealias SLTaskIdentifier = Int

public final class SLBleManager: NSObject {
    public static let shared = {
        let singleInstance = SLBleManager()
        return singleInstance
    }()
    
    private var state: CBManagerState = CBManagerState.unknown
    private var centralManager: CBCentralManager!
    private lazy var queue: dispatch_queue_t = {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let label = bundleId + ".ble"
        return DispatchQueue(label: label)
    }()
    private var scanServices: [CBUUID]? = nil
    private var scanTasks: [SLTaskIdentifier : SLBleScanTask] = [:]
    private override init() {}
    
    public func setUp() {
        self.centralManager = CBCentralManager(delegate: self, queue: self.queue, options: [CBCentralManagerOptionShowPowerAlertKey:true])
    }
    
    public func startScan(task: SLBleScanTask) throws {
        guard self.centralManager != nil else {
            throw SLError.internalStateError(msg: "invoker should call setUp() func to initialize an instance of CBCentralManager")
        }
        guard self.state == .poweredOn else {
            throw SLError.bleNotPowerOn
        }

        if !self.centralManager.isScanning {
            self.centralManager.scanForPeripherals(withServices: scanServices, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        }
        
        let address = unsafeBitCast(task, to: Int.self)
        if let oldTask = scanTasks[address] {
            
        } else {
            task.scanStateCallback(true)
            scanTasks.updateValue(task, forKey: address)
        }
    }
    
    func stopScan() {
//        self.cancelTimer()
        self.centralManager.stopScan()
        self.scanTasks.forEach { (_, task) in
            task.scanStateCallback(false)
        }
        self.scanTasks.removeAll()
    }
    
//    private func cancelTimer() {
//        guard let timer = self.timer else {
//            return
//        }
//        guard !timer.isCancelled else {
//            return
//        }
//        timer.cancel()
//        self.timer = nil
//        self.startScanTime = nil
//    }
    
    deinit {
//        cancelTimer()
    }
}

extension SLBleManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        var index = -1
//        repeat {
//            index = discoveredPeripheral.firstIndex { oldPeripheral in
//                guard
//                    let oldName = oldPeripheral.name,
//                    let name = peripheral.name,
//                    oldName.elementsEqual(name)
//                else {
//                    return false
//                }
//                return true
//            } ?? -1
//            if index >= 0 {
//                discoveredPeripheral.remove(at: index)
//            }
//        } while index >= 0
        scanTasks.forEach { (_, task) in
            DispatchQueue.main.async {
//                task.handler.peripheralDiscovered(peripheral, advertisementData, RSSI)
                task.peripheralDiscoveredCallback(peripheral, advertisementData, RSSI)
            }
        }
//        guard let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
//              !services.isEmpty
//        else {
//            return
//        }
//        for cbuuid in services {
//            guard cbuuid.uuidString.hasPrefix("A6DDE9") else {
//                break
//            }
//            let parameters = cbuuid.uuidString.components(separatedBy: "-")
//            guard parameters.count == 5 else {
//                break
//            }
//            let macAddress = parameters.last!
//            let wifiSsidSuffix = parameters[1] + parameters[2] + parameters[3]
//            let ipSuffix = parameters[0].replacingOccurrences(of: "A6DDE9", with: "")
//            
//        }
    }
}

extension SLBleManager: CBPeripheralDelegate {

}
