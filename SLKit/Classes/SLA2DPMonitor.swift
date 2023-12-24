//
//  SLA2DPMonitor.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/1.
//

import Foundation
import AVFoundation

public typealias SLA2DPDeviceCallback = ((_ device: SLA2DPDevice) -> Void)

public class SLA2DPMonitor {
    public static let shared = SLA2DPMonitor()
    
    private var isEnable = false {
        didSet {
            tasks.forEach { task in
                if isEnable {
                    task.startedCallback?()
                } else {
                    task.stoppedCallback?()
                }
            }
        }
    }
    private var tasks: [SLA2DPMonitorTask] = []
    
    private var currentDevice: SLA2DPDevice? {
        didSet {
            if oldValue == nil, let currentDevice {
                tasks.forEach { task in
                    task.deviceConnectedCallback?(currentDevice)
                }
            } else if let oldValue, currentDevice == nil {
                if shouldCallDeviceDisconnected {
                    tasks.forEach { task in
                        task.deviceDisconnectedCallback?(oldValue)
                    }
                } else {
                    shouldCallDeviceDisconnected = true
                }
            } else if let oldValue, let currentDevice {
                if oldValue.uid.elementsEqual(currentDevice.uid) {
                    if !oldValue.name.elementsEqual(currentDevice.name) {
                        tasks.forEach { task in
                            task.deviceUpdatedCallback?(currentDevice)
                        }
                    }
                } else {
                    // 不应该出现这种情况
                    SLLog.debug("切换A2DP设备：\(oldValue.name) -> \(currentDevice.name)，未检测到先断开\(oldValue.name)")
                }
            }
        }
    }
    
    private var shouldCallDeviceDisconnected = true
    
    private init() {}
    
    public func enable(resetDevice: Bool = false) {
        guard !isEnable else { return }
        SLLog.debug("开始监听A2DP，重置当前A2DP设备：\(resetDevice)")
        isEnable = true
        if resetDevice {
            currentDevice = nil
        } else {
            currentDevice = getA2DPDevice()
        }
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionRouteChanged(notification:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
    }
    
    /// 停止监控A2DP的连接状态
    /// - Parameters:
    ///   - clearDevice: 是否清除当前已连接的A2DP设备，是，则清除设备且不会执行设备断开的回调
    public func disable(resetDevice: Bool = false) {
        guard isEnable else { return }
        SLLog.debug("结束监听A2DP，重置当前A2DP设备：\(resetDevice)")
        NotificationCenter.default.removeObserver(self)
        if currentDevice != nil {
            shouldCallDeviceDisconnected = !resetDevice
        } else {
            shouldCallDeviceDisconnected = true
        }
        if resetDevice {
            currentDevice = nil
        }
        isEnable = false
    }
    
    private func getA2DPDevice() -> SLA2DPDevice? {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        if let portDescription = outputs.first(where: { description in
            return description.portType == AVAudioSessionPortBluetoothA2DP || description.portType == AVAudioSessionPortBluetoothHFP
        }) {
            return SLA2DPDevice(uid: portDescription.uid, name: portDescription.portName)
        }
        return nil
    }
    
    @objc private func handleAudioSessionRouteChanged(notification: Notification) {
        currentDevice = getA2DPDevice()
    }
    
    func connectedDevice() -> SLA2DPDevice? {
        return currentDevice
    }
    
    func startTask(_ task: SLA2DPMonitorTask) {
        if let _ = tasks.first(where: { existedTask in
            existedTask.id == task.id
        }) {
            
        } else {
            tasks.append(task)
        }
        enable()
    }
    
    func stopTask(_ task: SLA2DPMonitorTask) {
        var index = tasks.firstIndex { existedTask in
            existedTask.id == task.id
        }
        while index != nil {
            // TODO: 移除任务时须考虑到在多线程执行中，remove(at:index)前是否有可能在startTask方法中执行了tasks.append(task)，导致移除的index与预期不符
            tasks.remove(at: index!)
            index = tasks.firstIndex { existedTask in
                existedTask.id == task.id
            }
        }
        task.stoppedCallback?()
    }
}
