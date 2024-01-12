//
//  SLMotionManager.swift
//  test
//
//  Created by shenjianfei on 2023/8/12.
//

import UIKit
import CoreMotion

public class SLMotionManager: NSObject {
    
    private let sensitive = 0.845
    private let sensitiveX = 0.655

    private let motionManager = CMMotionManager()
    var direction: UIInterfaceOrientation = .unknown
    var xyTheta: Double = 0
    var x: Double = 0
    var y: Double = 0
    var z: Double = 0

    var updateOrientationBlock:((UIInterfaceOrientation)->Void)?
    
    var updateAngleBlock:((Double,Double)->Void)?
    
    public var orientation: UIInterfaceOrientation {
        return direction
    }
    
    // 每隔一个间隔做轮询
    public func start() {
        motionManager.deviceMotionUpdateInterval = 0.1
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) {[weak self] (motio, error) in
                guard let motion = motio else {
                    return
                }
                self?.deviceMotion(motion: motion)
            }
        }
    }
    
    @objc
    func deviceMotion(motion: CMDeviceMotion) {
        let x = motion.gravity.x
        let y = motion.gravity.y
        let z = motion.gravity.z
        let alphaX = acos(x) * 180 / Double.pi // x轴与重力的夹角
        let betaY = acos(y) * 180 / Double.pi // y轴与重力的夹角
        let thetaZ = acos(z) * 180 / Double.pi // z轴与重力的夹角
        if thetaZ > 157.5 || thetaZ < 22.5 {
            // thetaz > 157.5 手机屏幕朝上近似平放，thetaZ < 22.5 手机屏幕朝下近似平放
        } else {
            if fabs(betaY - 90) <= 22.5 {
                // 当y轴与重力夹角在67.5到112.5之间时（即x轴与重力夹角在157.5-180或者0-22.5之间），则认为是横屏
                if alphaX >= 157.5 {
                    print("横屏（向左）")
                    self.updataDirection(.landscapeLeft)
                } else if alphaX <= 22.5 {
                    print("横屏（向右）")
                    self.updataDirection(.landscapeRight)
                }
            } else if (fabs(alphaX - 90) <= 22.5){
                /*
                 如果刚好位于边界角度时，会因为细微抖动导致角度不断在边界区上下跳动，屏幕就会不断切换横竖屏
                 所以边界角度应该适当放宽，即竖屏与横屏之间留了45度的缓冲
                 */
                if betaY >= 112.5 {
                    print("竖屏（正）")
                    self.updataDirection(.portrait)
                } else if betaY <= 77.5 {
                    print("竖屏（倒）")
                    self.updataDirection(.portraitUpsideDown)
                }
            }
        }
        
//        if fabs(z) > 0.5 {
//            if y < 0 {
//                if fabs(y) > 0.32 {
//                    self.updataDirection(.portrait)
//                }
//            } else {
//                if y > 0.45 {
//                    self.updataDirection(.portraitUpsideDown)
//                }
//            }
//            if x < 0 {
//                if fabs(x) > sensitiveX {
//                    self.updataDirection(.landscapeLeft)
//                }
//            } else {
//                if x > sensitiveX {
//                    self.updataDirection(.landscapeRight)
//                }
//            }
//        } else {
//            if y < 0 {
//                if fabs(y) > sensitive {
//                    self.updataDirection(.portrait)
//                }
//            } else {
//                if y > sensitive {
//                    self.updataDirection(.portraitUpsideDown)
//                }
//            }
//            if x < 0 {
//                if fabs(x) > sensitive {
//                    self.updataDirection(.landscapeLeft)
//                }
//            } else {
//                if x > sensitive {
//                    self.updataDirection(.landscapeRight)
//                }
//            }
//        }
    }
    
    private func updataDirection(_ direction: UIInterfaceOrientation) {
        if self.direction != direction {
            self.direction = direction
            self.updateOrientationBlock?(direction)
        }
    }
    
    public func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}
