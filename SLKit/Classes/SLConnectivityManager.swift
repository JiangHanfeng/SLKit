//
//  SLConnectivityManager.swift
//  Pods-SLKit_Example
//
//  Created by 蒋函锋 on 2023/11/3.
//

import Foundation
import CoreLocation
import CoreBluetooth

public final class SLConnectivityManager {
    public static let shared = {
        let singleInstance = SLConnectivityManager()
        return singleInstance
    }()
    
    var a2dpDevice: SLA2DPDevice? {
        get {
            return SLA2DPMonitor.shared.connectedDevice()
        }
    }
    
    private init() {
        
    }
    
    public func connectWifi(ssid: String, passphrase: String, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        SLNetworkManager.shared.connectWifi(ssid: ssid, passphrase: passphrase, completionHandler: completionHandler)
    }
           
    public func getConnectedWifi(completionHandler: @escaping ((_ ssid: String?, _ bssid: String?, _ error: Error?) -> Void)) {
        SLNetworkManager.shared.getConnectedWifi(completionHandler: completionHandler)
    }
    
    public func startScan<U: SLDeviceBuilder>(
        deviceBuilder: U.Type,
        timeout: SLTimeInterval = .infinity,
        filter: ((U.Device) -> Bool)? = nil,
        discovered: @escaping ((_ devices: [U.Device]) -> Bool),
        errored: @escaping ((SLError) -> Void),
        finished: @escaping (() -> Void)
    ) {
        SLDeviceScanTask(anyDevice: SLAnyDevice(base: deviceBuilder))
            .start(timeout: timeout, filter: filter, discovered: discovered, errored: errored, finished: finished)
    }
    
    public func stopScan() {
        SLBleManager.shared.stopScan()
    }
    
    public func connectDevice<T: SLBaseDevice>(_ device: T) {
        switch device.type {
        case .freestyle(key: _):
            let connection = SLBleConnection(peripheral: device.peripheral) { result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    break
                }
            } disconnectedCallback: { error in
                
            }
        default:
            break
        }
    }
    
    public func disconnectDevice() {
        SLBleManager.shared.disconnectAll()
    }
    
    public func asyncScan<U: SLDeviceBuilder>(
        deviceBuilder: U.Type,
        timeout: SLTimeInterval = .infinity,
        filter: @escaping ((U.Device) -> Bool)
    ) async throws -> U.Device {
        let task = SLDeviceScanTask(anyDevice: SLAnyDevice(base: deviceBuilder))
        return try await task.asyncStart(timeout: timeout, filter: filter)
    }
    
    public func asyncBleConnection<U: SLDeviceBuilder>(
        deviceBuilder: U.Type,
        timeout: SLTimeInterval = .seconds(15),
        target: @escaping ((U.Device) -> Bool)
    ) async throws -> Bool {
        let device = try await asyncScan(deviceBuilder: deviceBuilder, timeout: timeout) { target($0) }
        return try await withCheckedThrowingContinuation { continuation in
            let task = SLBleConnection(peripheral: device.peripheral, timeout: timeout) { result in
                switch result {
                case .success(_):
                    continuation.resume(returning: true)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            } disconnectedCallback: { error in
                
            }
        }
    }
    
    public func asyncTcpSocketConnection() {
        
    }
}
