//
//  AppDelegate.swift
//  SLKit
//
//  Created by wiwi on 11/03/2023.
//  Copyright (c) 2023 wiwi. All rights reserved.
//

import UIKit
import SLKit

enum SCLUserDefaultKey: String {
    case agreedPrivacyPolicy = "agreedPrivacyPolicy"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var dateFormatter = DateFormatter()
    
    private var backgroundId: UIBackgroundTaskIdentifier?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //        dateFormatter.dateFormat = "yy年MM月dd日 HH时mm分ss秒"
        if let btMac = SCLUtil.getBTMac(), !btMac.isEmpty {
            
        } else {
            let tempMac = SCLUtil.getTempMac()
            print("设备临时mac地址：\(tempMac)")
        }
        if let backImage = UIImage(named: "icon_back_dark") {
            UINavigationBar.appearance().backIndicatorImage = backImage.withRenderingMode(.alwaysOriginal)
            UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage.withRenderingMode(.alwaysOriginal)
        }
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear], for: .highlighted)
        var rootVc: UIViewController?
        if UserDefaults.standard.bool(forKey: SCLUserDefaultKey.agreedPrivacyPolicy.rawValue) {
            SLCentralManager.shared.requestPermission { _ in
                
            }
            rootVc = SCLHomeViewController()
        } else {
            rootVc = SCLWelcomeViewController()
        }
        let nav = UINavigationController(rootViewController: rootVc!)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        print("\(dateFormatter.string(from: Date())):程序将进入未激活状态")
        SLLog.debug("程序将进入未激活状态")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//        print("\(dateFormatter.string(from: Date())):程序已进入后台\n开启后台保活任务")
        SLLog.debug("程序已进入后台")
        applyTimeForBackgroundTask()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        print("\(dateFormatter.string(from: Date())):程序将进入前台")
        SLLog.debug("程序将进入前台")
        if let backgroundId, backgroundId != UIBackgroundTaskInvalid {
            application.endBackgroundTask(backgroundId)
            self.backgroundId = nil
            SLLog.debug("终止后台任务")
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        print("\(self.dateFormatter.string(from: Date())):程序即将退出")
        SLLog.debug("程序即将退出")
    }
    
    func selectFile() {
        let documentTypes = ["public.content", "public.text", "public.archive", "public.image",
                             "public.audiovisual-content", "com.adobe.pdf", "com.apple.keynote.key", "com.microsoft.word.doc",
                             "com.microsoft.excel.xls", "com.microsoft.powerpoint.ppt","public.item"]
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
        let vc = UIDocumentPickerViewController.init(documentTypes:documentTypes , in: .open)
        vc.modalPresentationStyle = .fullScreen
        vc.delegate = self
        vc.allowsMultipleSelection = true;
        vc.navigationController?.navigationBar.barTintColor = .white
        UIApplication.shared.currentController().present(vc, animated: true)
    }
    
    private func applyTimeForBackgroundTask() {
        if backgroundId == nil {
            SLLog.debug("开启后台任务")
            backgroundId = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
                if let backgroundId = self?.backgroundId {
                    UIApplication.shared.endBackgroundTask(backgroundId)
                    self?.backgroundId = nil
                    SLLog.debug("终止后台任务")
                }
                self?.applyTimeForBackgroundTask()
            })
            if let backgroundId, backgroundId > 0 {
                SLLog.debug("后台任务开启成功")
            } else {
                SLLog.debug("后台任务开启失败")
            }
        }
    }
}

extension AppDelegate : UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var files:[SLFileModel] = []
        _ = urls.map({ url in
            if url.startAccessingSecurityScopedResource(),
               let model = try? self.fileModel(with: url) {
                files.append(model)
                url.stopAccessingSecurityScopedResource()
            }
        })
        guard files.count > 0 else {
            /*
             sometimes the debugger will show "The view service did terminate with error: Error Domain=_UIViewServiceErrorDomain Code=1 "(null)" UserInfo={Terminated=disconnect method}"
             then the file won't be choosen by app
             */
            return
        }
    }
    
    
    private func fileModel(with documentUrl: URL) throws -> SLFileModel {
        var path1 : String
        if #available(iOS 16.0, *) {
            path1 = documentUrl.path()
        } else {
            path1 = documentUrl.path
        }
        let dirs = path1.split(separator: "/")
        guard !dirs.isEmpty else {
            throw NSError(domain: NSCocoaErrorDomain, code: -999, userInfo: [NSLocalizedDescriptionKey:"文件路径错误"])
        }
        let fileName = String(dirs.last!)
        let arr = String(dirs.last!).split(separator: ".")
        guard arr.count > 1 else {
            throw NSError(domain: NSCocoaErrorDomain, code: -999, userInfo: [NSLocalizedDescriptionKey:"文件名无法解析"])
        }
        let name = arr[0..<arr.count - 1].joined()
        let extensionName = String(arr.last!)
        let fm = FileManager()
        let tempPath1 = try FileManager.tempPath()
        try fm.copy(sourcePath: path1, desDirPath: tempPath1, renamed: fileName)
        return SLFileModel(path: tempPath1 + "/\(fileName)", name: name, extensionName: extensionName, time: Int(Date().timeIntervalSince1970*1000))
    }
}

