//
//  SLPeripheralManager.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/29.
//

import Foundation
import CoreBluetooth
import CoreLocation

public class SLPeripheralManager : NSObject {
    public static let shared = SLPeripheralManager(queue: DispatchQueue(label: "com.slkit.peripheralManager"))
    private var state = CBManagerState.unknown
    private var manager: CBPeripheralManager!
    public var stateUpdatedHandler: SLBleStateUpdatedHandler?
    private var locationManager: CLLocationManager!
    private var requestPermissionCallback: ((CLLocation) -> Void)?
    private override init() {}
    
    convenience init(queue: DispatchQueue, stateUpdatedHandler: SLBleStateUpdatedHandler? = nil) {
        self.init()
        self.stateUpdatedHandler = stateUpdatedHandler
        self.manager = CBPeripheralManager(delegate: self, queue: queue)
        self.locationManager = CLLocationManager()
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.delegate = self
    }
    
    public func available() -> Bool {
        return manager.state == .poweredOn
    }
    
    public func requestPermission() {
        
    }
    
    public func startAdvertising(_ advertisementData: [String : Any]?) throws {
        guard manager.state == .poweredOn else {
            throw SLError.bleNotPowerOn
        }
        var locationAuthStatus: CLAuthorizationStatus?
        if #available(iOS 14.0, *) {
            locationAuthStatus = locationManager.authorizationStatus
        } else {
            locationAuthStatus = CLLocationManager.authorizationStatus()
        }
        guard locationAuthStatus == .authorizedAlways || locationAuthStatus == .authorizedWhenInUse else {
            locationManager.requestAlwaysAuthorization()
            throw SLError.locationNotAllowed
        }
        manager.startAdvertising(advertisementData)
    }
    
    public func stopAdvertising() {
        manager.stopAdvertising()
        SLLog.debug("已停止广播")
    }
}

extension SLPeripheralManager: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if state != peripheral.state {
            state = peripheral.state
            stateUpdatedHandler?.handle(state)
        }
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            SLLog.debug("广播失败:\n\(error.localizedDescription)\n")
        } else {
            SLLog.debug("广播成功")
        }
    }
}

extension SLPeripheralManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                break
            default:
                break
            }
        } else {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                break
            default:
                break
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        SLLog.debug("ibeacon开始监听")
    }
    
    public func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
    }
}
