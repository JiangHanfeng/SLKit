//
//  SLAdjustingManager.swift
//  test
//
//  Created by shenjianfei on 2024/1/5.
//

import UIKit

private let Adjusting_Base_X_Key = "Adj_Base_X"
private let Adjusting_Base_Y_Key = "Adj_Base_Y"

private let Adjusting_Count = 127

private let Adjusting_MAX_INIT_X = 127
private let Adjusting_MAX_INIT_Y = 100

private let Adjusting_MAX_INIT_STEP = 5

private let Adjusting_Edge = 75.0


@available(iOS 13.0, *)
class SLAdjustingControlManager: NSObject {
    
    var adjustingMoveBlock:((Int,Int,Int)->Void)?
    var adjustingResultBlock:((Bool,String?)->Void)?
    var adjustingSensitivityBigBlock:(()->Void)?
    var adjustingTimeoutBlock:(()->Void)?
    
    private var basePoint:CGPoint?
    private var basePoints:[String] = []
    private var points:[String] = []
    
    private var adjustingValue:[Float] = []
    private var adjustingRuning = false
    private var adjustingId = 0
    private var baseX = 0
    private var baseY = 0
    private var baseOK = false
    private var existBase = false
    
    func startAdjustingControl(){
        if self.adjustingRuning {
            return
        }
        self.adjustingRuning = true
        self.adjustingId = Int(Date().timeIntervalSince1970)
        self.points.removeAll()
        self.basePoints.removeAll()
        self.adjustingValue.removeAll()
        self.baseOK = false
        if let baseX = UserDefaults.standard.object(forKey: Adjusting_Base_X_Key) as? Int,
           let baseY = UserDefaults.standard.object(forKey: Adjusting_Base_Y_Key) as? Int {
            self.baseX = baseX
            self.baseY = baseY
            self.existBase = true
        } else {
            self.baseX = Adjusting_MAX_INIT_X
            self.baseY = Adjusting_MAX_INIT_Y
            self.existBase = false
        }
        self.adjustingBasePoint(self.baseX, self.baseY)
        self.adjustingBaseTimeout()
    }
    
    func adjusting(_ point: CGPoint) {
        
        if !self.adjustingRuning {
            return
        }
        if self.baseOK,let basePoint = self.basePoint {
            let height = UIScreen.main.bounds.size.height
            if point.y > height - 50 {
                self.adjustingResultBlock?(false,nil)
                self.adjustingSensitivityBigBlock?()
                return
            }

            self.points.append("\(point)")
            let diff = abs(point.y - basePoint.y)
            //小于5的步长不做0判断
            if diff == 0,abs(self.adjustingIndex())>5 {
                self.adjustingResultBlock?(false,nil)
                return
            }
            self.adjustingValue.append(Float(diff))
            if self.adjustingValue.count == Adjusting_Count {
                self.adjustingRuning = false
                self.adjustingValue = self.adjustingValue.sorted { value1, value2 in
                    return value1 > value2
                }
                guard let adjustingValueData = self.correctAdjustingData() else {
                    self.adjustingResultBlock?(false,nil)
                    return
                }
                let adjustingData = "[\(adjustingValueData.joined(separator: ","))]"
                self.adjustingResultBlock?(true,adjustingData)
            } else {
                self.basePoint = point
                self.adjustingPoint(self.adjustingIndex(),self.baseX,self.baseY)
                self.adjustingTimeout()
            }
        } else {
            self.basePoints.append("\(point)")
            let width =  UIScreen.main.bounds.size.width
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 44
           
            if point.x > Adjusting_Edge,
               point.x < (width - Adjusting_Edge),
               point.y > statusBarHeight,
               point.y < (statusBarHeight + 100.0) {
                self.basePoint = point
                self.baseOK = true
                print("确认基准点")
                
                UserDefaults.standard.set(self.baseX, forKey: Adjusting_Base_X_Key)
                UserDefaults.standard.set(self.baseY, forKey: Adjusting_Base_Y_Key)
                UserDefaults.standard.synchronize()
                
                self.adjustingPoint(self.adjustingIndex(),self.baseX,self.baseY)
                self.adjustingTimeout()
                
            } else {
                
                if self.existBase {
                    self.existBase = false
                    
                    UserDefaults.standard.removeObject(forKey: Adjusting_Base_Y_Key)
                    UserDefaults.standard.removeObject(forKey: Adjusting_Base_X_Key)
                    UserDefaults.standard.synchronize()
                    
                    self.baseX = Adjusting_MAX_INIT_X
                    self.baseY = Adjusting_MAX_INIT_Y
                    
                } else {
                    if !(point.x > Adjusting_Edge && point.x < (width - Adjusting_Edge)) {
                        self.baseX =  self.baseX - Adjusting_MAX_INIT_STEP
                    }
                    
                    if !(point.y > statusBarHeight && point.y < (statusBarHeight + 100.0)) {
                        self.baseY = self.baseY - Adjusting_MAX_INIT_STEP
                    }
                }
                
                if self.baseX > 0 && self.baseY > 0 {
                    self.adjustingBasePoint(self.baseX, self.baseY)
                    self.adjustingBaseTimeout()
                } else {
                    print("基准点错误");
                    self.adjustingResultBlock?(false,nil)
                }
            }
        }
    }
    
    func endAdjustingControl(){
        if !self.adjustingRuning {
            return
        }
        self.adjustingRuning = false
        self.adjustingId = -1
        self.points.removeAll()
        self.basePoints.removeAll()
        self.adjustingValue.removeAll()
        self.basePoint = nil
    }
    
    func isOpenTouchControl()-> Bool {
        if #available(iOS 17.0, *){
            return true
        } else {
            return false
        }
    }
    
    private func correctAdjustingData()-> [String]? {
        var pointStrings:[String] = []
        var pointFloat: [Float] = []
        for i in 0..<self.adjustingValue.count {
            var vlaue = self.adjustingValue[i]
            if vlaue == 0 {
                print("出现相同的点：\(i)")
                if i != 0,i != self.adjustingValue.count-1 {
                    let value1 = self.adjustingValue[i-1]
                    let value2 = self.adjustingValue[i+1]
                    if value1 == 0 || value2 == 0 {
                        print("连续出现相同的点：\(i)")
                        return nil
                    }
                    vlaue = (value1 + value2)/2.0
                } else {
                    if i == 0 {
                        print("127和基准点一样")
                        return nil
                    } else if i == self.adjustingValue.count-1 {
                        let value1 = self.adjustingValue[self.adjustingValue.count-2]
                        if value1 == 0 {
                            print("连续出现相同的点：\(i)")
                            return nil
                        }
                        vlaue = value1/2.0
                    }
                }
            }
            pointFloat.append(vlaue)
        }
        pointStrings = pointFloat.sorted(by:{$0 < $1}).map { value in
            return String(format: "%.6f", value)
        }
        if pointStrings.count != Adjusting_Count {
            print("校准值没有127个")
            return nil
        }
        return pointStrings
    }
    
    
    private func adjustingIndex() -> Int{
        return self.adjustingValue.count % 2 == 0 ? Adjusting_Count - self.adjustingValue.count :  self.adjustingValue.count - Adjusting_Count
    }
    
    private func adjustingBasePoint(_ baseX: Int,_ baseY: Int) {
        self.adjustingMoveBlock?(0,baseX,baseY)
    }
    
    private func adjustingPoint(_ step: Int ,_ baseX: Int,_ baseY: Int) {
        self.adjustingMoveBlock?(step,baseX,baseY)
    }
    
    private func adjustingBaseTimeout(){
        let id = self.adjustingId
        let x = self.baseX
        let y = self.baseY
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if id == self.adjustingId,self.adjustingRuning,!self.baseOK,x == self.baseX, y ==  self.baseY {
                UserDefaults.standard.removeObject(forKey: Adjusting_Base_X_Key)
                UserDefaults.standard.removeObject(forKey: Adjusting_Base_Y_Key)
                UserDefaults.standard.synchronize()
                self.adjustingResultBlock?(false,nil)
                self.adjustingTimeoutBlock?()
            }
        }
    }
    
    private func adjustingTimeout(){
        let id = self.adjustingId
        let index = self.adjustingIndex()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if id == self.adjustingId,self.adjustingRuning,self.adjustingIndex() == index,self.adjustingIndex() != 0 {
                self.adjustingResultBlock?(false,nil)
                self.adjustingTimeoutBlock?()
            }
        }
    }
}
