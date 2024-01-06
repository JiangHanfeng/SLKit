//
//  SLKeepAliveManager.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import SLKit

class SLKeepAliveManager {
    public static let shared = SLKeepAliveManager()
    private init() {}
    
    private var currentTime: NSInteger = 0
    private var isBackRuning: Bool = false
    private var appForeground: Bool = false
    private var backgroundTask: SLBLEBackgroundTask = SLBLEBackgroundTask()
    private lazy var task: SLBackgroundTask = {
        let task = SLBackgroundTask.init(fileName:"silentAudio.m4a")
        return task
    }()
    
    func enterBackground() {
        SLLog.debug("进入后台")
        startBackRuning()
        appForeground = false
    }
    
    func enterForeground() {
        SLLog.debug("进入前台")
        appForeground = true
        stopBackRuning()
    }
    
    func configBackRuning(){
        self.task.backroundInterruptedBlock = { [weak self] run in
            if run {
//                guard let ori = self?.motionManager.direction else {
//                    return
//                }
//                self?.sendOrientation(ori)
            }
        }
    }
    
    func stopBackRuning() {
        if !isBackRuning {
            return
        }
        SLLog.debug("停止后台运行")
        self.isBackRuning = false
    }
    
    func startBackRuning() {
        if isBackRuning {
            return
        }
        SLLog.debug("开始后台运行")
        self.isBackRuning = true
        self.countAction()
        let application = UIApplication.shared
        if application.applicationState == .background {
            let appdelegate = application.delegate as! AppDelegate
            appdelegate.backgroundRun()
        }
    }
    
    @objc
    func countAction() {
        if !isBackRuning {
            return
        }
        self.currentTime += 1
        if(self.currentTime >= 15 * 1000){
            self.currentTime = 0
        }
        if self.currentTime % 15 == 0 {
            self.task.startTask(time: 1, target: self, selector: #selector(countAction1))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.task.stopTask()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.countAction()
        }
    }
    
    @objc
    func countAction1() {
        
    }
}
