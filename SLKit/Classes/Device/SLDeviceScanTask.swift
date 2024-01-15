//
//  SLDeviceScanTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/7.
//

import Foundation

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
    
    var id: String {
        return "\(address)"
    }
    
    func start() {
        
    }
    
    func exception(e: SLError) {
        
    }
    
    func update(progress: [T]) {
        
    }
    
    func completed(result: [T]) {
        
    }
    
    public func terminate() {
//        bleScanTask.terminate()
    }
    
    public static func == (lhs: SLDeviceScanTask<T>, rhs: SLDeviceScanTask<T>) -> Bool {
        return lhs.id == rhs.id
    }
    
    private var bleScanTaskId: String? {
        didSet {
            if let oldValue, bleScanTaskId == nil {
                SLScanPeripheralTask.stop(with: oldValue)
            }
        }
    }
    
    private var devices: [SLTimedDevice] = []
    
    public var discoveredDevices: [T] {
        return devices.map { item in
            item.device
        }
    }
    
    private var timeout: SLTimeInterval = .infinity
    private var checkWork: SLCancelableWork?
    
    let anyDevice: SLAnyDevice<T>
    private var filter: ((T) -> Bool)?
    private var discovered: (([T]) -> Bool)?
    private var errored: ((SLError) -> Void)?
    private var finished: (() -> Void)?
    private var refreshTimer: Timer?
    
    public init(anyDevice: SLAnyDevice<T>) {
        self.anyDevice = anyDevice
    }
    
    public func start(
        timeout: SLTimeInterval = .infinity,
        refreshInterval: TimeInterval,
        filter: SLDeviceFilter? = nil,
        discovered: @escaping (([T]) -> Bool),
        errored: @escaping ((SLError) -> Void),
        finished: @escaping (() -> Void)
    ) {
        self.timeout = timeout
        self.filter = filter
        self.discovered = discovered
        self.errored = errored
        self.finished = finished
        let task = SLScanPeripheralTask { peripheral in
            if let device = self.anyDevice.build(peripheral: peripheral.peripheral, advertisementData: peripheral.advertisementData, rssi: peripheral.rssi) {
                if filter?(device) != false {
                    if let index = self.devices.firstIndex(where: { item in
                        item.device == device
                    }) {
                        return true
                    } else {
                        self.devices.append(SLTimedDevice(device: device, createTime: ProcessInfo.processInfo.systemUptime))
                        let continueScan = discovered(self.discoveredDevices)
                        if !continueScan {
                            self.refreshTimer?.invalidate()
                        }
                        return continueScan
                    }
                    
                }
                return true
            } else {
                return true
            }
        } exceptionHandler: { error in
            self.bleScanTaskId = nil
            errored(error)
            self.refreshTimer?.invalidate()
        }
        self.bleScanTaskId = task.id
        switch self.timeout {
        case .seconds(let timeout):
            self.checkWork?.cancel()
            self.checkWork = nil
            self.checkWork = SLCancelableWork(delayTime: .seconds(Int(timeout)), closure: { [weak self] in
                if let _ = self?.bleScanTaskId {
                    SLLog.debug("扫描超时")
                    self?.bleScanTaskId = nil
                    errored(SLError.bleScanTimeout)
                    task.terminate()
                    self?.refreshTimer?.invalidate()
                }
            })
            self.checkWork?.start(at: DispatchQueue.global(qos: .background))
        case .infinity:
            self.checkWork?.cancel()
            self.checkWork = nil
        }
        task.start()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { [weak self] _ in
            self?.onRefresh(withTimeInterval: refreshInterval)
        })
        refreshTimer?.fire()
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
            _ = discovered?(discoveredDevices)
        }
    }
    
    public func start(
        timeout: SLTimeInterval = .infinity,
        filter: @escaping SLDeviceFilter
    ) async throws -> T {
        guard bleScanTaskId == nil else {
            throw SLError.internalStateError("can't call \(#function):the internal property named 'bleScanTaskId' should be nil")
        }
        self.timeout = timeout
        return try await withCheckedThrowingContinuation { continuation in
            let task = SLScanPeripheralTask { peripheral in
                if let device = self.anyDevice.build(peripheral: peripheral.peripheral, advertisementData: peripheral.advertisementData, rssi: peripheral.rssi), filter(device) {
                    self.bleScanTaskId = nil
                    continuation.resume(returning: device)
                    return false
                } else {
                    return true
                }
            } exceptionHandler: { error in
                self.bleScanTaskId = nil
                continuation.resume(throwing: error)
            }
            self.bleScanTaskId = task.id
            switch self.timeout {
            case .seconds(let timeout):
                self.checkWork?.cancel()
                self.checkWork = nil
                self.checkWork = SLCancelableWork(delayTime: .seconds(Int(timeout)), closure: { [weak self] in
                    if let _ = self?.bleScanTaskId {
                        SLLog.debug("扫描超时")
                        self?.bleScanTaskId = nil
                        continuation.resume(throwing: SLError.bleScanTimeout)
                    }
                })
                self.checkWork?.start(at: DispatchQueue.global(qos: .background))
            case .infinity:
                self.checkWork?.cancel()
                self.checkWork = nil
            }
            task.start()
        }
    }
    
    deinit {
        print("\(self) deinit")
    }
}

