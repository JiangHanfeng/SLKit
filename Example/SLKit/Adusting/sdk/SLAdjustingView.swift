//
//  SLAdjustingControlView.swift
//  test
//
//  Created by shenjianfei on 2024/1/5.
//

import UIKit
import SLKit

class SLAdjustingView: UIView {

    private lazy var animationView: SLAdustingControlAnimationView = {
        let view = SLAdustingControlAnimationView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var runingAdjustingOri = false
    private lazy var detectionComplete = false
    private var detectionIndex = 0
    private var lockOrientation = false
    private var motionManager = SLMotionManager()
    
    var adjustingOrientationCompleteBlock:(()->Void)?
    var adjustingLeftOrRightOrientationCompleteBlock:(()->Void)?
    var adjustingPointUpdated:((_ point: CGPoint) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.animationView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAdjustingOrientation(){
        if self.runingAdjustingOri {
            return
        }
        self.motionManager.start()
        self.runingAdjustingOri = true
        self.detectionIndex = 0
        self.detectionComplete = false
        self.lockOrientation = false
        self.detectionOrientation()
    }
    
    func endAdjustingOrientation(){
        if !self.runingAdjustingOri {
            return
        }
        self.motionManager.stop()
        self.runingAdjustingOri = false
    }
    
    private func detectionOrientation(){
        if !self.runingAdjustingOri {
            return
        }
        
        let ori = motionManager.orientation // 陀螺仪方向
        if self.detectionComplete {
            if ori == .portrait {
                self.adjustingOrientationCompleteBlock?()
            }
        } else {
            if ori == .landscapeLeft || ori == .landscapeRight {
                self.detectionIndex = self.detectionIndex + 1
                if self.detectionIndex > 3 {
                    let dOri = UIDevice.current.orientation
                    self.lockOrientation = dOri == .portrait
                    self.detectionComplete = true
                    self.adjustingLeftOrRightOrientationCompleteBlock?()
                }
            } else {
                self.detectionIndex = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.detectionOrientation()
        }
    }
        
//    func prepareStartAdjustingControl(_ block:(Bool)->Void){
//        //TODO: 准备校准控制 tcp 发 cmd: 10 回复 cmd 10
//    }
    
    func startAdjustingControl(){
        self.animationView.startAnimation()
        //TODO: 开始校准控制 SLAdjustingControlManager 里的 startAdjustingControl()
    }

    func endAdjustingControl(){
        self.animationView.endAnimation()
        //TODO: 开始校准控制 SLAdjustingControlManager 里的 endAdjustingControl()
    }
    
    override func layoutSubviews() {
        self.animationView.frame = self.bounds
    }
}

extension SLAdjustingView {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }
        //TODO: 提交校准点 SLAdjustingControlManager 里的 adjusting(_ point: CGPoint)
        adjustingPointUpdated?(point)
    }
}
