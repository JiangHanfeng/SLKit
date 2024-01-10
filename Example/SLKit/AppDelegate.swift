//
//  AppDelegate.swift
//  SLKit
//
//  Created by wiwi on 11/03/2023.
//  Copyright (c) 2023 wiwi. All rights reserved.
//

import UIKit
import SLKit
import TZImagePickerController

enum SCLUserDefaultKey: String {
    case agreedPrivacyPolicy = "agreedPrivacyPolicy"
}

public let enterForegroundNoti: Notification.Name =  NSNotification.Name.init("enterForeground")
public let enterBackgroundNoti: Notification.Name =  NSNotification.Name.init("enterBackground")

private let k_Send_file = "group.com.igrs.SmartConnect"
private let k_Send_file_path = "sendFilePaths"
private let k_Can_Send_file = "canSendFilePaths"
private let k_SmartConnect_url = "smartconnect://"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var dateFormatter = DateFormatter()
    
    private var backgroundId: UIBackgroundTaskIdentifier?
    fileprivate var backgroundTask = UIBackgroundTaskInvalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        SLLog.prepare()
//        if SCLUtil.isFirstLaunch() {
//            SCLUtil.setFirstAirPlay(true)
//            SCLUtil.markNotFirstLaunch()
//        }
        if let btMac = SCLUtil.getBTMac(), !btMac.isEmpty {
//            SCLUtil.setBTMac(nil)
        } else {
            let tempMac = SCLUtil.getTempMac()
            SLLog.debug("设备临时mac地址：\(tempMac)")
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

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
//        if (url.scheme?.elementsEqual("file") == true) {
//            SLLog.debug("app open url:\(url)")
//            guard let nav = UIApplication.shared.currentController() as? UINavigationController else {
//                return true
//            }
//            guard let homeVc = nav.viewControllers.first as? SCLHomeViewController else {
//                return true
//            }
//            guard let _ = homeVc.device?.localClient else {
//                try? UIApplication.shared.toast("请连接设备后再发送文件", duration: 3)
//                return true
//            }
//            return true
//        }
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
//        SLLog.debug("程序已进入后台")
//        applyTimeForBackgroundTask()
        SLKeepAliveManager.shared.enterBackground()
        NotificationCenter.default.post(Notification(name: enterBackgroundNoti))
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//        print("\(dateFormatter.string(from: Date())):程序将进入前台")
//        SLLog.debug("程序将进入前台")
//        if let backgroundId, backgroundId != UIBackgroundTaskInvalid {
//            application.endBackgroundTask(backgroundId)
//            self.backgroundId = nil
//            SLLog.debug("终止后台任务")
//        }
        SLKeepAliveManager.shared.enterForeground()
        NotificationCenter.default.post(Notification(name: enterForegroundNoti))
        backgroundTask = UIBackgroundTaskInvalid
        application.endBackgroundTask(backgroundTask)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        guard let userDefaults = UserDefaults.init(suiteName: k_Send_file) else {
            return
        }
        SLLog.debug("k_Can_Send_file = \(userDefaults.bool(forKey: k_Can_Send_file))")
        SLLog.debug("k_Send_file_path = \(String(describing: userDefaults.object(forKey: k_Send_file_path)))")
        guard let newShare = userDefaults.object(forKey: k_Can_Send_file) as? Bool,
            newShare == true,
            let paths = userDefaults.object(forKey: k_Send_file_path) as? [String],
            paths.count > 0  else{
            return
        }
        let list:[String] = []
        userDefaults.set(list, forKey: k_Send_file_path)
        userDefaults.set(false, forKey: k_Can_Send_file)
        DispatchQueue.main.async {
            guard let homeVc = UIApplication.shared.currentController() as? SCLHomeViewController else {
                return
            }
            guard let _ = homeVc.device?.localClient else {
                try? UIApplication.shared.toast("请连接设备后再发送文件", duration: 3)
                return
            }
            let sendFile = SLTransferManager.share().currentSendFileTransfer()
            guard sendFile == nil || sendFile!.files.isEmpty else {
                try? UIApplication.shared.toast("请等待当前文件发送完成", duration: 3)
                return
            }
//            SLAnalyticsManager.share().sendFile(with: .freestyleSendFileShare)
            var models: [SLFileModel] = []
            _ = paths.map { url in
                if let model = SLTransferManager.share().createSendFileModel(withPath: url) {
                    models.append(model)
                }
            }
            SLTransferManager.share().sendFiles(models) { _, _ in
                
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        print("\(self.dateFormatter.string(from: Date())):程序即将退出")
        SLLog.debug("程序即将退出")
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

extension AppDelegate {
    
    func backgroundRun() {
        let application = UIApplication.shared
        if backgroundTask == UIBackgroundTaskInvalid {
            let begintime = CFAbsoluteTimeGetCurrent()
            SLLog.debug("申请后台运行:\(begintime)")
            backgroundTask = application.beginBackgroundTask(expirationHandler: {
                let endtime = CFAbsoluteTimeGetCurrent()
                SLLog.debug("===========后台任务结束了==========时间： \(endtime - begintime)")
                application.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskInvalid
            })
        }
    }
    
    func selectFile() {
        let documentTypes = ["public.content", "public.text", "public.archive", "public.image",
                             "public.audiovisual-content", "com.adobe.pdf", "com.apple.keynote.key", "com.microsoft.word.doc",
                             "com.microsoft.excel.xls", "com.microsoft.powerpoint.ppt","public.item"]
//        UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.black], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.black], for: .highlighted)
        let vc = UIDocumentPickerViewController.init(documentTypes:documentTypes , in: .open)
        vc.modalPresentationStyle = .fullScreen
        vc.delegate = self
        vc.allowsMultipleSelection = true
        UIApplication.shared.currentController()?.present(vc, animated: true)
    }
    
    func sendPhoto(){
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization {[weak self] _ in
                DispatchQueue.main.async {
                    self?.sendPhoto()
                }
            }
            return
        }
        if status == .denied || status == .restricted {
            //没有相册权限
            return
        }
        self.selectSendPhoto()
    }
    
    private func selectSendPhoto() {
        let rootVc =  UIApplication.shared.currentController()
        //maxImagesCount:最多可以选择几张图片
        let vc = TZImagePickerController(maxImagesCount: 9, delegate: nil)!
        vc.allowTakeVideo = false //是否允许拍视频
        vc.allowPickingVideo = true //是否允许选择视频
        vc.allowCrop = true //是否裁剪
        vc.needCircleCrop = false //是否带边框裁剪
        vc.allowCameraLocation = false
        vc.modalPresentationStyle = .custom
        rootVc?.present(vc, animated: true)
        //选中图片后做相应的处理
        vc.didFinishPickingPhotosHandle = { photos,assets,isSelectOriginalPhoto in
            if let imgs = photos {
                if imgs.count > 0 {
                    SLTransferManager.share().startSendFile()
                    //拿到图片 做相应的处理
                    var files: [SLFileModel] = []
                    _  = imgs.map { img in
                        if let model = SLTransferManager.share().createSendFileModel(with: img) {
                            files.append(model)
                        }
                    }
                    SLTransferManager.share().sendFiles(files) { _, _ in }
                }
            }
        }
        
        vc.didFinishPickingVideoHandle = { coverImage,asset in
            if let aideoAsset = asset, aideoAsset.mediaType == .video {

                let options = PHVideoRequestOptions()
                options.version = .current
                options.deliveryMode = .automatic
                options.isNetworkAccessAllowed = true
                
                PHImageManager.default().requestAVAsset(forVideo: aideoAsset, options: options) { avasset,_,info in
                    DispatchQueue.main.async {
                        
                        guard let assetUrl = avasset as? AVURLAsset else {
                            return
                        }
                        SLTransferManager.share().startSendFile()
                        let data = NSData.init(contentsOf: assetUrl.url) ?? NSData()
                        let url = assetUrl.url.absoluteString
                        let urls = url.split(separator: "/")

                        if urls.count > 0,
                           let name = aideoAsset.value(forKey: "filename") as? String,
                           data.length > 0,
                           let model =  SLTransferManager.share().createSendFileModel(withVideo: name, data: data as Data) {
                            SLTransferManager.share().sendFiles([model]) { _,_ in }
                        }
                    }
                }
            }
        }
    }
}


extension AppDelegate : UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
//        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear], for: .highlighted)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear], for: .highlighted)
        SLTransferManager.share().startSendFile()
        var files:[SLFileModel] = []
        _ = urls.map({ url in
            if url.startAccessingSecurityScopedResource(),
               let model = SLTransferManager.share().createSendFileModel(withPath: url.path) {
                files.append(model)
                url.stopAccessingSecurityScopedResource()
            }
        })
        SLTransferManager.share().sendFiles(files) { _, _ in }
    }
}

