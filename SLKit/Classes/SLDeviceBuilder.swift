//
//  SLDeviceBuilder.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/5.
//

import Foundation
import CoreBluetooth

/// 设备类型
public enum SLDeviceType {
    case freestyle(key: Data?)
    case vehicle(ssid: String, ip: String, port: Int, freeCount: Int)
}

/// 本sdk适配的所有类型的设备都应该具有的属性，抽象成协议
public protocol SLBaseDevice: Equatable {
    var type: SLDeviceType { get }
    var peripheral: CBPeripheral { get }
    var name: String { get }
    var mac: [UInt8] { get }
}

/// 从CBPeripheral映射到自定义的设备类型
public protocol SLDeviceBuilder {
    /// 此协议的实现者应该关联一个具体的类型，以便在执行映射方法后返回该类型的设备实例，所有这个关联类型应该具备SLDeviceAttribute所描述的所有属性
    associatedtype Device: SLBaseDevice
    
    static func build(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) -> Device?
}
