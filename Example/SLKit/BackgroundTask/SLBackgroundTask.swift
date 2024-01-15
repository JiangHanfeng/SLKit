//
//  SLBackgroundTask.swift
//  MiracastDisplay
//
//  Created by shenjianfei on 2022/6/15.
//

import UIKit
import AVFoundation
import SLKit

class SLBackgroundTask: NSObject {
    
    private var fileName: NSString?
    private var player: AVAudioPlayer?
    private var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    private var timer: Timer?
    private var target: AnyObject?
    private var selector: Selector?
    private var timeCount: TimeInterval?
    
    var backroundInterruptedBlock:((Bool)->Void)?
    
    init(fileName: NSString) {
        self.fileName = fileName
        self.timer = nil
        self.bgTask = UIBackgroundTaskIdentifier.invalid
    }
    
    func startTask(time: TimeInterval,target: AnyObject,selector: Selector) {
        self.endTime()
        self.timeCount = time
        self.target = target
        self.selector = selector
        self.createTask()
    }
    
    private func endTime() {
        self.timer?.invalidate()
        self.timer = nil
        if self.player?.isPlaying ?? true {
            self.player?.stop()
            self.player = nil
        }
    }
    
    private  func createTask() {
        DispatchQueue.main.async{
            if self.isRunning() {
                self.stopTask()
            }
            while self.isRunning() {
                Thread.sleep(forTimeInterval: 30)
            }
            self.playAudio()
        }
    }
    
    private func playAudio(){
        NotificationCenter.default.addObserver(self, selector: #selector(audioInterrupted(noti:)), name: AVAudioSession.interruptionNotification, object: nil)
        self.bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
            SLLog.debug("后台结束运行")
            guard let identifier = self?.bgTask else {
                return
            }
            UIApplication.shared.endBackgroundTask(identifier)
            self?.bgTask = UIBackgroundTaskIdentifier.invalid
            self?.endTime()
        })
        DispatchQueue.main.async{
            self.startTime()
        }
    }
    
    private func startTime(){
        do{
            guard let timeCount = self.timeCount,
                  let target = self.target,
                  let selector = self.selector else {
                return
            }
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            if self.player == nil {
                let bytes: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x26, 0x0, 0x0, 0x0, 0x57, 0x41, 0x56, 0x45, 0x66, 0x6d, 0x74, 0x20, 0x10, 0x0, 0x0, 0x0, 0x1, 0x0, 0x1, 0x0, 0x44, 0xac, 0x0, 0x0, 0x88, 0x58, 0x1, 0x0, 0x2, 0x0, 0x10, 0x0, 0x64, 0x61, 0x74, 0x61, 0x2, 0x0, 0x0, 0x0, 0xfc, 0xff]
                let data = Data.init(bytes:bytes , count: bytes.count)
                let docsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)
                let docsDir = docsPaths.first ?? ""
                let filePath = "\(docsDir)/\(self.fileName ?? "")"
                let url = URL.init(fileURLWithPath: filePath)
                try data.write(to: url)
                
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.volume = 0.01
                self.player?.numberOfLoops = -1
                self.player?.prepareToPlay()
            }
            self.audioPlay(self.player!)

            if self.timer == nil {
                self.timer = Timer.scheduledTimer(timeInterval: timeCount,
                                                  target: target,
                                                  selector: selector,
                                                  userInfo: nil,
                                                  repeats: true)
                RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
            }
        } catch {}
    }
    
    func audioPlay(_ player: AVAudioPlayer){
        if player == self.player {
            player.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                player.stop()
                DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
                    self.audioPlay(player)
                }
            }
        }
    }
    
    @objc
    func audioInterrupted(noti: NSNotification){
        guard let dic = noti.userInfo else {
            return
        }
        let type = dic[AVAudioSessionInterruptionTypeKey] as! Int
        if type == 1 {
            self.endTime()
        } else {
            self.createTask()
        }
        self.backroundInterruptedBlock?(type != 1)
    }
    
    func stopTask(){
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        self.endTime()
        if self.bgTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskIdentifier.invalid
        }
    }
    
    func isRunning()->Bool {
        if self.bgTask == UIBackgroundTaskIdentifier.invalid {
            return false
        }
        return true
    }
}

