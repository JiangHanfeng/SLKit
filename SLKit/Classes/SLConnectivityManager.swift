//
//  SLConnectivityManager.swift
//  Pods-SLKit_Example
//
//  Created by 蒋函锋 on 2023/11/3.
//

import Foundation
import CoreLocation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import CoreBluetooth

public final class SLConnectivityManager {
    public static let shared = {
        let singleInstance = SLConnectivityManager()
        return singleInstance
    }()
    
    private init() {}
    
    public func connectWiFi(ssid: String, passphrase: String, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        guard !ssid.isEmpty && !passphrase.isEmpty else {
            DispatchQueue.main.async {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [NSLocalizedDescriptionKey:"请指定要连接WiFi的名称及密码"])
                completionHandler(error)
            }
            return
        }
        if #available(iOS 11.0, *) {
            let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: false)
            NEHotspotConfigurationManager.shared.apply(configuration, completionHandler: completionHandler)
        } else {
            DispatchQueue.main.async {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: [NSLocalizedDescriptionKey:"系统版本低于iOS11，暂不支持连接指定WiFi"])
                completionHandler(error)
            }
        }
    }
    
    public func getConnectedWiFi(completionHandler: @escaping ((_ ssid: String?, _ bssid: String?, _ error: Error?) -> Void)) {
        guard CLLocationManager.authorizationStatus() == .authorized || CLLocationManager.authorizationStatus() == .authorizedAlways ||
                CLLocationManager.authorizationStatus() == .authorizedWhenInUse else {
            CLLocationManager().requestAlwaysAuthorization()
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUserAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey:"获取已连接WiFi信息需定位权限"])
            completionHandler(nil, nil, error)
            return
        }
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { network in
                completionHandler(network?.ssid, network?.bssid, nil)
            }
        } else {
            guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else { return }
            guard let name = interfaceNames.first, let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String: Any] else {
                completionHandler(nil, nil, nil)
                return
            }
            let ssid = info["ssid"] as? String
            let bssid = info["bssid"] as? String
            completionHandler(ssid, bssid, nil)
        }
    }
    
    public func startScanDevices(
        scanStateUpdated: @escaping ((_ isScanning: Bool) -> Void),
        filter: @escaping ((_ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ rssi: NSNumber) -> Bool),
        devicesUpdated: @escaping ((_ array: [SLDevice]) -> Void)
    ) throws {
        do {
            try SLBleScanTask { isScanning in
                scanStateUpdated(isScanning)
            } peripheralDiscoveredCallback: { peripheral, advertisementData, rssi in
                if filter(peripheral, advertisementData, rssi) {
                    
                } else {
                    
                }
            }.resume()
        } catch let e {
            throw e
        }
    }
}
