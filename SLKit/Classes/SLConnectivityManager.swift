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
    
    private var bleStateUpdatedHandlers: [SLBleStateUpdatedHandler] = []
    var a2dpDevice: SLA2DPDevice? {
        get {
            return SLA2DPMonitor.shared.connectedDevice()
        }
    }
    
    private var peripheralManager = SLPeripheralManager(queue: DispatchQueue(label: "com.slkit.peripheral"))
    
    private init() {}
    
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
        SLCentralManager.shared.stopScan()
    }
    
    public func connectDevice<T: SLBaseDevice>(_ device: T) {
        switch device.type {
        case .freestyle(key: _):
            let connection = SLCentralConnection(peripheral: device.peripheral) { result in
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
        SLCentralManager.shared.disconnectAll()
    }
    
    public func bleAvailable() -> Bool {
        return SLCentralManager.shared.available() && peripheralManager.available()
    }
}
