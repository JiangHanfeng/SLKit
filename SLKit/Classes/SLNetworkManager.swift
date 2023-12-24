//
//  SLNetworkManager.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/1.
//

import Foundation
import Network
import NetworkExtension
import CoreLocation
import SystemConfiguration.CaptiveNetwork

public class SLNetworkManager {
    public enum InterfaceName {
        
    }
    public static let shared = SLNetworkManager()
    private init() {}
    
    private var monitor: NWPathMonitor?
    
    private var getGatewayTimeoutWorkItem: DispatchWorkItem?
    private var getConnectedWifiTimeoutWorkItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: (Bundle.main.bundleIdentifier ?? "com.") + ".SLKit.SLNetworkManager.NWPathMonitor")
    
    public func connectWifi(ssid: String, passphrase: String, completionHandler: @escaping ((_ error: Error?) -> Void)) {
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
    
    public func getConnectedWifi(completionHandler: @escaping ((_ ssid: String?, _ bssid: String?, _ error: Error?) -> Void)) {
        guard CLLocationManager.authorizationStatus() == .authorizedAlways ||
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
    
    public func getGatewayAddress(completionHandler: @escaping ((String?, Error?) -> Void)) {
        stopMonitorWifi()
        monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor?.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                var gateway: String?
                if #available(iOS 13.0, *) {
                    if !path.gateways.isEmpty {
                        let endPoint = String(describing: path.gateways.first)
                        let components = endPoint.components(separatedBy: ":")
                        if components.count == 2 {
                            self?.stopMonitorWifi()
                            gateway = components.first
                            DispatchQueue.main.async {
                                completionHandler(gateway!, nil)
                            }
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            } else {
                self?.stopMonitorWifi()
                DispatchQueue.main.async {
                    completionHandler(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: [NSLocalizedDescriptionKey:"wifi已断开"]))
                }
            }
        }
        getGatewayTimeoutWorkItem = DispatchWorkItem(block: { [weak self] in
            if (self?.monitor) != nil {
                self?.stopMonitorWifi()
                completionHandler(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: [NSLocalizedDescriptionKey:"获取网关地址超时"]))
            }
        })
        queue.asyncAfter(deadline: .now() + .seconds(10), execute: getGatewayTimeoutWorkItem ?? DispatchWorkItem(block: {}))
        monitor?.start(queue: queue)
    }
    
    private func stopMonitorWifi() {
        getGatewayTimeoutWorkItem?.cancel()
        getGatewayTimeoutWorkItem = nil
        monitor?.cancel()
        monitor = nil
    }
}
