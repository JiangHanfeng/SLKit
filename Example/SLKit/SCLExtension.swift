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
//        if #available(iOS 15.0, *) {
//            
//        } else 
        if #available(iOS 13.0, *) {
            window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
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
    
    public func currentWindow() -> UIWindow {
        var window: UIWindow?
//        if #available(iOS 15.0, *) {
//            window = UIApplication.shared.connectedScenes
//                .lazy
//                .compactMap { $0.activationState == .foregroundActive ? ($0 as? UIWindowScene) : nil}
//                .first(where: { $0.keyWindow != nil })?.keyWindow
//        } else 
        if #available(iOS 13.0, *) {
            window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        } else {
            window = UIApplication.shared.keyWindow
        }
        guard let window else {
            fatalError("can not get window at this moment!!!")
        }
        return window
    }
    
    public func currentController() -> UIViewController {
        guard let root = currentWindow().rootViewController else {
            fatalError("can not get rootViewController at this moment!!!")
        }
        return getCurrentViewController(root)
    }
    
    /// 通过递归拿到当前显示的UIViewController
    public func getCurrentViewController(_ vc: UIViewController) -> UIViewController {
        if vc is UINavigationController {
            let nav = vc as! UINavigationController
            if nav.viewControllers.count > 0 {
                return getCurrentViewController(nav.viewControllers.last!)
            }
            return nav
        } else if vc is UITabBarController {
            let tabbarController = vc as! UITabBarController
            if let selectedViewController = tabbarController.selectedViewController {
                return selectedViewController
            }
            return tabbarController
        } else if vc.presentedViewController != nil {
            return getCurrentViewController(vc.presentedViewController!)
        } else {
            return vc
        }
    }
}

extension UIViewController {
    func toast(_ msg: String, image: UIImage? = nil) {
//        var style = ToastStyle()
//        style.messageColor = .white
//        style.backgroundColor = .init(red: 70/255.0, green: 72/255.0, blue: 82/255.0, alpha: 0.8)
//        style.messageFont = .systemFont(ofSize: 14)
//        view.makeToast(msg, duration: 3.0, position: .bottom, image: image, style: style)
        DispatchQueue.main.async {
            try? UIApplication.shared.toast(msg, duration: 3)
        }
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

let screenHeight: CGFloat = UIScreen.main.bounds.height
let screenWidth: CGFloat = UIScreen.main.bounds.width
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

// MARK: 获取本机存储空间
extension UIDevice {
    func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
    
    //MARK: Get String Value
    var totalDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var freeDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var usedDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalDiskSpaceInMB:String {
        return MBFormatter(totalDiskSpaceInBytes)
    }
    
    var freeDiskSpaceInMB:String {
        return MBFormatter(freeDiskSpaceInBytes)
    }
    
    var usedDiskSpaceInMB:String {
        return MBFormatter(usedDiskSpaceInBytes)
    }
    
    //MARK: Get raw value
    var totalDiskSpaceInBytes:Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return 0 }
        return space
    }
    
    /*
     Total available capacity in bytes for "Important" resources, including space expected to be cleared by purging non-essential and cached resources. "Important" means something that the user or application clearly expects to be present on the local system, but is ultimately replaceable. This would include items that the user has explicitly requested via the UI, and resources that an application requires in order to provide functionality.
     Examples: A video that the user has explicitly requested to watch but has not yet finished watching or an audio file that the user has requested to download.
     This value should not be used in determining if there is room for an irreplaceable resource. In the case of irreplaceable resources, always attempt to save the resource regardless of available capacity and handle failure as gracefully as possible.
     */
    var freeDiskSpaceInBytes:Int64 {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return space ?? 0
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
               let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            } else {
                return 0
            }
        }
    }
    
    var usedDiskSpaceInBytes:Int64 {
        return totalDiskSpaceInBytes - freeDiskSpaceInBytes
    }
}

extension FileManager {
    static func tempPath() throws -> String {
        let tempFileDirPath = NSHomeDirectory() + "/Documents/tmpFiles"
        let fm = FileManager()
        if fm.fileExists(atPath: tempFileDirPath) {
            return tempFileDirPath
        }
        try fm.createDirectory(atPath: tempFileDirPath, withIntermediateDirectories: false)
        return tempFileDirPath
    }
    
    func copy(sourcePath: String, desDirPath: String, renamed: String) throws {
        let fm = FileManager()
        let toPath = desDirPath + "/\(renamed)"
        if !fm.fileExists(atPath: toPath) {
            try fm.copyItem(atPath: sourcePath, toPath: toPath)
        }
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

extension UIFont {

    class func oversized(_ weight: UIFont.Weight = .regular) -> UIFont{
        return UIFont.systemFont(ofSize: 30, weight: weight)
    }
    
    class func nomalSized(_ weight: UIFont.Weight = .regular) -> UIFont{
        return UIFont.systemFont(ofSize: 17, weight: weight)
    }
    
    class func trumpetSized(_ weight: UIFont.Weight = .regular) -> UIFont{
        return UIFont.systemFont(ofSize: 15, weight: weight)
    }
    
    class func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular)-> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}

extension Int {
    static func timestamp2FormattedDataString(from: Int, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(from))
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
