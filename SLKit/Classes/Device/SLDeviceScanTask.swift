//
//  SLDeviceScanTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/7.
//

import Foundation
import CoreBluetooth

public class SLDeviceScanTask<T: SLBaseDevice>: SLTask {
    
    struct SLTimedDevice {
        let device: T
        let createTime: TimeInterval
    }
    
    public typealias SLDeviceFilter = (T) -> Bool
    
    public typealias SLDevicesUpdatedCallback = ([T]) -> Void
    
    typealias Exception = SLError
    
    typealias Progress = [T]
    
    typealias Result = [T]
    
    private lazy var address: Int = {
        return unsafeBitCast(self, to: Int.self)
    }()
    
    var id: Int {
        return address
    }
    
    func start() {}
    
    func exception(e: SLError) {}
    
    func update(progress: [T]) {}
    
    func completed(result: [T]) {}
    
    public func terminate() {
        scanPeripheralTask?.terminate()
        scanPeripheralTask = nil
    }
    
    public static func == (lhs: SLDeviceScanTask<T>, rhs: SLDeviceScanTask<T>) -> Bool {
        return lhs.id == rhs.id
    }
    
//    private var bleScanTaskId: Int? {
//        didSet {
//            if let oldValue, bleScanTaskId == nil {
//                SLScanPeripheralTask.stop(with: oldValue)
//            }
//        }
//    }
    private var scanPeripheralTask: SLScanPeripheralTask?
    
    private var devices: [SLTimedDevice] = []
    
    public var discoveredDevices: [T] {
        return devices.map { item in
            item.device
        }
    }
    
    private var checkWork: SLCancelableWork?
    
    private let anyDevice: SLAnyDevice<T>
    private var deviceFilter: ((T) -> Bool)?
    private var deviceListUpdatedHandler: (([T]) -> Void)?
    private var exceptionHandler: ((SLError) -> Void)?
    private var refreshTimer: Timer?
    
    public init(anyDevice: SLAnyDevice<T>) {
        self.anyDevice = anyDevice
    }
    
    deinit {
        print("\(self) deinit")
    }
    
    public func start(
        services: [CBUUID]? = nil,
        timeout: TimeInterval,
        refreshInterval: TimeInterval,
        deviceFilter: SLDeviceFilter? = nil,
        deviceListUpdatedHandler: @escaping (([T]) -> Void),
        exceptionHandler: @escaping ((SLError) -> Void)
    ) {
        self.deviceFilter = deviceFilter
        self.deviceListUpdatedHandler = deviceListUpdatedHandler
        self.exceptionHandler = exceptionHandler
        let task = SLScanPeripheralTask()
        task.discoveredPeripheralHandler = { peripheral in
            guard let device = self.anyDevice.build(peripheral: peripheral.peripheral, advertisementData: peripheral.advertisementData, rssi: peripheral.rssi) else {
                return
            }
            guard self.deviceFilter?(device) != false else {
                return
            }
            if let index = self.devices.firstIndex(where: { item in
                item.device == device
            }) {
                // 仅替换列表中已存在的设备，更新其时间，不对外抛出更新列表事件
                self.devices.replaceSubrange(index..<index+1, with: [SLTimedDevice(device: device, createTime: ProcessInfo.processInfo.systemUptime)])
            } else {
                self.devices.append(SLTimedDevice(device: device, createTime: ProcessInfo.processInfo.systemUptime))
                self.deviceListUpdatedHandler?(self.discoveredDevices)
            }
        }
        task.exceptionHandler = { error in
            self.scanPeripheralTask?.terminate()
            self.scanPeripheralTask = nil
            self.stopCheckwork()
            self.stopTimer()
            exceptionHandler(error)
        }
        if timeout > 0 {
            stopCheckwork()
            startCheckwork(timeout: timeout)
        } else {
            stopCheckwork()
        }
        task.start(with: services)
        scanPeripheralTask = task
        stopTimer()
        startTimer(refreshInterval: refreshInterval)
    }
    
    private func startCheckwork(timeout: TimeInterval) {
        checkWork = SLCancelableWork(delayTime: .seconds(Int(timeout)), closure: { [weak self] in
            if let task = self?.scanPeripheralTask {
                SLLog.debug("扫描超时")
                task.terminate()
                self?.scanPeripheralTask = nil
                self?.refreshTimer?.invalidate()
                self?.exceptionHandler?(SLError.bleScanTimeout)
                self?.stopCheckwork()
            }
        })
        checkWork?.start(at: DispatchQueue.global(qos: .background))
    }
    
    private func stopCheckwork() {
        checkWork?.cancel()
        checkWork = nil
    }
    
    private func startTimer(refreshInterval: TimeInterval) {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { [weak self] _ in
            self?.onRefresh(withTimeInterval: refreshInterval)
        })
        refreshTimer?.fire()
    }
    
    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func onRefresh(withTimeInterval: TimeInterval) {
        let currentTime = ProcessInfo.processInfo.systemUptime
        var removed = false
        devices.removeAll { item in
            let shouldRemove = currentTime - item.createTime >= withTimeInterval
            if shouldRemove {
                removed = true
            }
            return shouldRemove
        }
        if removed {
            deviceListUpdatedHandler?(discoveredDevices)
        }
    }
}

