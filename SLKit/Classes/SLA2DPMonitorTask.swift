//
//  SLA2DPMonitorTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/4.
//

import Foundation

public class SLA2DPMonitorTask: SLTask {
    
    typealias Exception = SLError
    
    typealias Progress = SLA2DPDevice
    
    typealias Result = SLA2DPDevice
    
    public func start() {
        SLA2DPMonitor.shared.startTask(self)
    }
    
    func exception(e: SLError) {
        SLA2DPMonitor.shared.stopTask(self)
    }
    
    func update(progress: SLA2DPDevice) {
        
    }
    
    func completed(result: SLA2DPDevice) {
        
    }
    
    public func terminate() {
        SLA2DPMonitor.shared.stopTask(self)
    }
    
    public static func == (lhs: SLA2DPMonitorTask, rhs: SLA2DPMonitorTask) -> Bool {
        return lhs.id == rhs.id
    }
    
    var startedCallback: (() -> Void)?
    var stoppedCallback: (() -> Void)?
    var deviceConnectedCallback: SLA2DPDeviceCallback?
    var deviceUpdatedCallback: SLA2DPDeviceCallback?
    var deviceDisconnectedCallback: SLA2DPDeviceCallback?
    
    private lazy var address: Int = {
        return unsafeBitCast(self, to: Int.self)
    }()
    
    var id: String {
        return "\(address)"
    }
    
    public var connectedDevice: SLA2DPDevice? {
        get {
            return SLA2DPMonitor.shared.connectedDevice()
        }
    }
    
    public init(
        startedCallback: (() -> Void)? = nil,
        stoppedCallback: (() -> Void)? = nil,
        connectedCallback: SLA2DPDeviceCallback? = nil,
        updatededCallback: SLA2DPDeviceCallback? = nil,
        disconnectedCallback: SLA2DPDeviceCallback? = nil
    ) {
        self.startedCallback = startedCallback
        self.startedCallback = stoppedCallback
        self.deviceConnectedCallback = connectedCallback
        self.deviceUpdatedCallback = updatededCallback
        self.deviceDisconnectedCallback = disconnectedCallback
        SLLog.debug("A2DP监控任务：\(address)已初始化")
    }
    
    deinit {
        SLLog.debug("A2DP监控任务：\(self.id)已销毁")
    }
}


