//
//  SCLExtension.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import Toast_Swift

extension UIApplication {
    func toast(_ msg: String, duration: TimeInterval, tag: Int = 0) throws {
        var window: UIWindow?
        if #available(iOS 15.0, *) {
            window = UIApplication.shared.connectedScenes
                .lazy
                .compactMap { $0.activationState == .foregroundActive ? ($0 as? UIWindowScene) : nil}
                .first(where: { $0.keyWindow != nil })?.keyWindow
        } else if #available(iOS 13.0, *) {
            window = UIApplication.shared.windows.first
        } else {
            window = UIApplication.shared.keyWindow
        }
        guard let window else {
            throw NSError(domain: NSErrorDomain(string: "UI Error") as String, code: -999, userInfo: [NSLocalizedDescriptionKey:"key window not found"])
        }
        var style = ToastStyle()
        style.messageColor = .white
        style.backgroundColor = .init(red: 70/255.0, green: 72/255.0, blue: 82/255.0, alpha: 0.8)
        style.messageFont = .systemFont(ofSize: 14)
        window.makeToast(msg, duration: duration, position: .bottom, style: style)
    }
}

extension UIViewController {
    func toast(_ msg: String, image: UIImage? = nil) {
        var style = ToastStyle()
        style.messageColor = .white
        style.backgroundColor = .init(red: 70/255.0, green: 72/255.0, blue: 82/255.0, alpha: 0.8)
        style.messageFont = .systemFont(ofSize: 14)
        view.makeToast(msg, duration: 3.0, position: .bottom, image: image, style: style)
    }
    
    func transitionToChild(_ controller: UIViewController, removeCurrent: Bool = true, configChildViewRect: ((_ childView: UIView) -> Void)) {
        let currentChild = childViewControllers.last
        if currentChild?.isEqual(controller) == true {
            return
        }
        if let targetControllerIndex = childViewControllers.firstIndex(where: {
            controller.isEqual($0)
        }) {
            childViewControllers[targetControllerIndex].removeFromParentViewController()
        }
        addChildViewController(controller)
        let targetView = controller.view
        if let targetView {
            var targetViewAdded = false
            for subview in view.subviews {
                if subview.isEqual(targetView) {
                    targetViewAdded = true
                    break
                }
            }
            if !targetViewAdded {
                view.addSubview(targetView)
                configChildViewRect(targetView)
                if childViewControllers.count > 1 {
                    // 只有在切换两个子controller时才有平移
                    targetView.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
                }
            }
        }
        var currentChildView: UIView?
        if let currentChild {
            currentChildView = currentChild.view
            if removeCurrent {
                currentChild.removeFromParentViewController()
            }
        }
        if targetView != nil || currentChildView != nil {
            var moveTo = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
            if let tx = targetView?.transform.tx, tx < 0 {
                moveTo = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            }
            if targetView?.transform.tx != 0 {
                // 有平移才会有透明变化
                targetView?.alpha = 0
            }
            UIView.animate(withDuration: 0.25) {
                targetView?.transform = CGAffineTransform(translationX: 0, y: 0)
                targetView?.alpha = 1
                currentChildView?.transform = moveTo
                currentChildView?.alpha = 0
            } completion: { _ in
                targetView?.alpha = 1
                currentChildView?.alpha = 0
                if removeCurrent {
                    currentChildView?.removeFromSuperview()
                }
            }
        }
    }
}

extension UIView {
    func setBorder(width: CGFloat, cornerRadius: CGFloat, color: UIColor) {
        layer.masksToBounds = true
        layer.borderWidth = width
        layer.cornerRadius = cornerRadius
        layer.borderColor = color.cgColor
    }
    
    func setGradientBackgroundColors(colors: [UIColor], locations: [NSNumber], startPoint: CGPoint? = nil, endPoint: CGPoint? = nil) {
        var gradientLayer: CAGradientLayer?
        if let sublayers = layer.sublayers {
            for sublayer in sublayers {
                if let aGradientLayer = sublayer as? CAGradientLayer {
                    gradientLayer = aGradientLayer
                    break
                }
            }
        }
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer()
            layer.insertSublayer(gradientLayer!, at: 0)
        }
        gradientLayer?.frame = bounds
        gradientLayer?.colors = colors.map({ $0.cgColor })
        gradientLayer?.locations = locations
        if let startPoint {
            gradientLayer?.startPoint = startPoint
        } else {
            gradientLayer?.startPoint = CGPoint.zero
        }
        if let endPoint {
            gradientLayer?.endPoint = endPoint
        } else {
            gradientLayer?.endPoint = CGPoint(x: 1, y: 1)
        }
    }
}

extension UIColor {
    
    class func colorWithHex(hexStr:String) -> UIColor{
        return UIColor.colorWithHex(hexStr : hexStr, alpha:1)
    }
    
    class func colorWithHex(hexStr:String, alpha:Float) -> UIColor{
        
        var cStr = hexStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased() as NSString;
        
        if(cStr.length < 6){
            return UIColor.clear;
        }
        
        if(cStr.hasPrefix("0x")){
            cStr = cStr.substring(from: 2) as NSString
        }
        
        if(cStr.hasPrefix("#")){
            cStr = cStr.substring(from: 1) as NSString
        }
        
        if(cStr.length != 6){
            return UIColor.clear
        }
        
        let rStr = (cStr as NSString).substring(to: 2)
        let gStr = ((cStr as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bStr = ((cStr as NSString).substring(from: 4) as NSString).substring(to: 2)
        
        var r: UInt32 = 0x0
        var g: UInt32 = 0x0
        var b: UInt32 = 0x0
        
        Scanner.init(string: rStr).scanHexInt32(&r)
        Scanner.init(string: gStr).scanHexInt32(&g)
        Scanner.init(string: bStr).scanHexInt32(&b)
        
        return UIColor.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(alpha));
    }
}

extension UIDevice {
    class func heightOfAddtionHeader() -> CGFloat {
        if UIDevice.current.isIPhoneXorLater() {
            return 44.0
        } else {
            return 20.0
        }
    }
    
    class func heightOfAddtionFooter() -> CGFloat {
        if UIDevice.current.isIPhoneXorLater() {
            return 34.0
        } else {
            return 0.0
        }
    }
    
    /// 底部安全区高度
    public class func safeDistanceBottom() -> CGFloat {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            guard scenes.count > 0,
                  let scene = scenes.first else {
                return self.heightOfAddtionFooter()
            }
            guard let windowScene = scene as? UIWindowScene else { return self.heightOfAddtionFooter() }
            guard let window = windowScene.windows.first else { return self.heightOfAddtionFooter() }
            return window.safeAreaInsets.bottom == 0 ? self.heightOfAddtionFooter() : window.safeAreaInsets.bottom
        } else {
            // Fallback on earlier versions
            return self.heightOfAddtionFooter()
        }
    }
    
    //是否有齐刘海
    public func isIPhoneXorLater()->Bool {
        if UIDevice.safeDistanceTop() > 20 {
            return true
        }
        return false
    }
    
    public class func isPad() -> Bool {
        return  UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public class func modelName() -> String{
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    public class func safeDistanceTop() -> CGFloat {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            return  window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 44
        } else {
            return 44
        }
    }
    
    public class func deviceName() -> String{
        if #available(iOS 16.0, *) {
            return "iPhone"
        } else {
            return UIDevice.current.name
        }
    }
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        self.clipsToBounds = true
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.setBackgroundImage(colorImage, for: forState)
        }
    }
}

extension URL {
    var parameters: [String:String]? {
        guard let query = self.query else { return nil}
        var queryStrings = [String: String]()
        for pair in query.components(separatedBy: "&") {
            let key = pair.components(separatedBy: "=")[0]
            let value = pair
                .components(separatedBy:"=")[1]
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? ""
            queryStrings[key] = value
        }
        return queryStrings
    }
}

import RxSwift
extension ObservableType {
    static func createFromResultCallback<E: Error>(_ fn: @escaping (@escaping ((Result<Element, E>) -> Void)) -> ()) -> Observable<Element> {
        return Observable.create { observer in
            fn { result in
                switch result {
                case .success(let value):
                    observer.onNext(value)
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
