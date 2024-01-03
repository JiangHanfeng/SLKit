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

public enum SLNetworkType : String {
    case celluar = "pdp_ip0"
    case wifi = "en0"
}

public class SLNetworkManager {
    public static let shared = SLNetworkManager()
    private init() {
        monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                if #available(iOS 13.0, *) {
                    if !path.gateways.isEmpty {
                        let endPoint = String(describing: path.gateways.first!)
                        let components = endPoint.components(separatedBy: ":")
                        if components.count == 2 {
                            self?.gateway = components.first
                        }
                    } else {
                        self?.gateway = nil
                    }
                } else {
                    // Fallback on earlier versions
                    self?.gateway = nil
                }
                self?.ipv4OfWifi = self?.getIP(for: .wifi)
            } else {
                self?.gateway = nil
                self?.ipv4OfWifi = nil
            }
        }
    }
    
    private var isInitial = true
    private let monitor: NWPathMonitor!
    private var gateway: String?
    public var ipv4OfWifi: String? {
        didSet {
            if isInitial {
                isInitial = false
                ipv4OfWifiUpdated?(ipv4OfWifi)
                return
            }
            if let oldValue {
                if let ipv4OfWifi {
                    if !ipv4OfWifi.elementsEqual(oldValue) {
                        ipv4OfWifiUpdated?(ipv4OfWifi)
                    }
                } else {
                    ipv4OfWifiUpdated?(nil)
                }
            } else if let ipv4OfWifi {
                ipv4OfWifiUpdated?(ipv4OfWifi)
            }
        }
    }
    private let queue = DispatchQueue(label: (Bundle.main.bundleIdentifier ?? "com.") + ".SLKit.SLNetworkManager.NWPathMonitor")
    public var ipv4OfWifiUpdated: ((String?) -> Void)?
    
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
    
    public func startMonitorWifi() {
        monitor.start(queue: queue)
    }
    
    private func stopMonitorWifi() {
        monitor.cancel()
    }
    
    public func getIP(for networkType: SLNetworkType) -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == networkType.rawValue {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
}
