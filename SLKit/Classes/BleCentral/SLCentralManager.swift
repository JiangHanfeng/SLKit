//
//  SLCentralManager.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/11/3.
//

import Foundation
import CoreBluetooth

typealias SLTaskIdentifier = Int

public typealias SLBleStateUpdatedHandlerId = Int

public struct SLBleStateUpdatedHandler {
    let handle: ((CBManagerState) -> Void)
    public init(handle: @escaping (CBManagerState) -> Void) {
        self.handle = handle
    }
}

public final class SLCentralManager: NSObject {
    public static let shared = {
        let singleInstance = SLCentralManager()
        return singleInstance
    }()
    
    public var state: CBManagerState = CBManagerState.unknown
    private var centralManager: CBCentralManager!
    private lazy var queue: DispatchQueue = {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let label = bundleId + ".ble"
        return DispatchQueue(label: label)
    }()
    public var stateUpdateHandler: SLBleStateUpdatedHandler?
    private var scanServices: [CBUUID]? = nil
    private var scanTasks: [SLScanPeripheralTask] = []
    private var connections: [SLCentralConnection] = []
    private var discoverServicesTasks: [SLDiscoverBleServiceTask] = []
    private var discoverCharacteristicsTasks: [SLDiscoverBleCharacteristicTask] = []
    private var readCharacteristicTasks: [SLReadBleCharacteristicTask] = []
    private var initialState: CBManagerState?
    private var requestPermissionCallback: ((CBManagerState) -> Void)?
    private override init() {}
    
    public func available() -> Bool {
        return centralManager.state == .poweredOn
    }
    
    public func requestPermission(result: @escaping ((CBManagerState) -> Void)) {
        self.requestPermissionCallback = result
        if let initialState {
            result(initialState)
        }
        if self.centralManager == nil {
            self.centralManager = CBCentralManager(delegate: self, queue: self.queue, options: [CBCentralManagerOptionShowPowerAlertKey:true])
        }
    }
    
    public func startScanTask(_ task: SLScanPeripheralTask) {
        guard self.centralManager != nil else {
            task.exception(e: SLError.internalStateError("startScanTask should call requestPermission() func to initialize an instance of CBCentralManager"))
            return
        }
        guard self.state == .poweredOn else {
            task.exception(e: SLError.bleNotPowerOn)
            return
        }

        if !self.centralManager.isScanning {
            self.centralManager.scanForPeripherals(withServices: scanServices, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        }
        
        if let _ = scanTasks.first(where: { existedTask in
            existedTask.id == task.id
        }) {
            // 如果该扫描任务已存在，不做任何操作
        } else {
            SLLog.debug("扫描任务(\(task.id))已开始")
            scanTasks.append(task)
        }
    }
    
    func stopScanTask(id: Int) {
        scanTasks.filter { item in
            item.id == id
        }.forEach { item in
            stopScanTask(item)
        }
    }
    
    func stopScanTask(_ task: SLScanPeripheralTask) {
        var index = scanTasks.firstIndex { item in
            item.id == task.id
        }
        while index != nil {
            // TODO: 考虑是否需要加锁
            let scanTask = scanTasks[index!]
            SLLog.debug("移除ble扫描任务:\(scanTask.id)")
            scanTasks.remove(at: index!)
            index = scanTasks.firstIndex { item in
                item.id == task.id
            }
        }
        if scanTasks.isEmpty {
            centralManager.stopScan()
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
        scanTasks.removeAll()
    }
    
    func startConnection(_ connection: SLCentralConnection) throws {
        guard self.centralManager != nil else {
            throw SLError.internalStateError("startConnection should call requestPermission() func to initialize an instance of CBCentralManager")
        }
        guard self.state == .poweredOn else {
            throw SLError.bleNotPowerOn
        }
        if let _ = connections.first(where: { existedConnection in
            existedConnection.peripheral.isEqual(connection.peripheral)
        }) {
            
        } else {
            connection.update(progress: .connecting)
            connections.append(connection)
        }
        centralManager.connect(connection.peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey:true])
    }
    
    func stopConnection(_ connection: SLCentralConnection) {
        centralManager.cancelPeripheralConnection(connection.peripheral)
    }
    
    func startDiscoverServices(_ task: SLDiscoverBleServiceTask) throws {
        guard self.centralManager != nil else {
            throw SLError.internalStateError("startDiscoverServices should call requestPermission() func to initialize an instance of CBCentralManager")
        }
        guard self.state == .poweredOn else {
            throw SLError.bleNotPowerOn
        }
        if let _ = discoverServicesTasks.first(where: { existedTask in
            existedTask.peripheral.isEqual(task.peripheral)
        }) {
            
        } else {
            discoverServicesTasks.append(task)
            task.started?()
            task.peripheral.delegate = self
            task.peripheral.discoverServices(nil)
        }
    }
    
    func startDiscoverCharacterisics(_ task: SLDiscoverBleCharacteristicTask) throws {
        guard self.centralManager != nil else {
            throw SLError.internalStateError("startDiscoverCharacterisics should call requestPermission() func to initialize an instance of CBCentralManager")
        }
        guard self.state == .poweredOn else {
            throw SLError.bleNotPowerOn
        }
        if let _ = discoverCharacteristicsTasks.first(where: { existedTask in
            existedTask.peripheral.isEqual(task.peripheral) && existedTask.service.isEqual(task.service)
        }) {
            
        } else {
            discoverCharacteristicsTasks.append(task)
            task.started?()
            task.peripheral.delegate = self
            task.peripheral.discoverCharacteristics(nil, for: task.service)
        }
    }
    
    func startReadCharacteristic(_ task: SLReadBleCharacteristicTask) throws {
        guard self.centralManager != nil else {
            throw SLError.internalStateError("startReadCharacteristic should call requestPermission() func to initialize an instance of CBCentralManager")
        }
        guard self.state == .poweredOn else {
            throw SLError.bleNotPowerOn
        }
        if let _ = readCharacteristicTasks.first(where: { existedTask in
            existedTask.peripheral.isEqual(task.peripheral) && existedTask.characteristic.isEqual(task.characteristic)
        }) {
            
        } else {
            readCharacteristicTasks.append(task)
            task.started?()
            task.peripheral.delegate = self
            task.peripheral.readValue(for: task.characteristic)
        }
        
    }
        
    func disconnectAll() {
        connections.forEach { [unowned self] connection in
            self.centralManager.cancelPeripheralConnection(connection.peripheral)
        }
    }
    
    deinit {
        
    }
}

extension SLCentralManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if initialState == nil {
            initialState = central.state
            DispatchQueue.main.async {
                self.requestPermissionCallback?(central.state)
            }
        }
        if state != central.state {
            state = central.state
            stateUpdateHandler?.handle(state)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        scanTasks.forEach { task in
            DispatchQueue.main.async {
                task.update(progress: SLPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI))
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connections.filter { item in
            item.peripheral.isEqual(peripheral)
        }.forEach { item in
            item.update(progress: .connected)
            item.completed(result: .success(Void()))
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connections.filter { item in
            item.peripheral.isEqual(peripheral)
        }.forEach { item in
            item.update(progress: .initial)
            item.completed(result: .failure(SLError.bleConnectionFailure(error)))
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connections.filter { item in
            item.peripheral.isEqual(peripheral)
        }.forEach { item in
            if let error {
                item.update(progress: .disconnectedWithError)
                item.exception(e: .bleDisconnected(error))
            } else {
                item.update(progress: .initial)
            }
        }
    }
}

extension SLCentralManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        var index = discoverServicesTasks.firstIndex { existedTask in
            existedTask.peripheral.isEqual(peripheral)
        }
        while index != nil {
            let task = discoverServicesTasks[index!]
            discoverServicesTasks.remove(at: index!)
            index = discoverServicesTasks.firstIndex { existedTask in
                existedTask.peripheral.isEqual(peripheral)
            }
            DispatchQueue.main.async {
                task.completion?(peripheral.services ?? [], nil)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var index = discoverCharacteristicsTasks.firstIndex { existedTask in
            existedTask.peripheral.isEqual(peripheral) && existedTask.service.isEqual(service)
        }
        while index != nil {
            let task = discoverCharacteristicsTasks[index!]
            discoverCharacteristicsTasks.remove(at: index!)
            index = discoverCharacteristicsTasks.firstIndex { existedTask in
                existedTask.peripheral.isEqual(peripheral)
            }
            DispatchQueue.main.async {
                task.completion?(service.characteristics ?? [], nil)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        var index = readCharacteristicTasks.firstIndex { existedTask in
            existedTask.peripheral.isEqual(peripheral) && existedTask.characteristic.isEqual(characteristic)
        }
        while index != nil {
            let task = readCharacteristicTasks[index!]
            readCharacteristicTasks.remove(at: index!)
            index = readCharacteristicTasks.firstIndex { existedTask in
                existedTask.peripheral.isEqual(peripheral) && existedTask.characteristic.isEqual(characteristic)
            }
            DispatchQueue.main.async {
                task.completion?(characteristic.value, nil)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        SLLog.debug("外设:\(peripheral.name ?? "")的service发生改变，主动断开连接")
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
