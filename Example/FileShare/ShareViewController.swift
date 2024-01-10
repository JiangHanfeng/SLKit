//
//  ShareViewController.swift
//  FileShare
//
//  Created by 蒋函锋 on 2024/1/9.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import Social

private let k_Send_file = "group.com.igrs.SmartConnect"
private let k_Send_file_path = "sendFilePaths"
private let k_Can_Send_file = "canSendFilePaths"
private let k_SmartConnect_url = "smartconnect://"

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        var pathArray:[String] = []
        DispatchQueue.global().async {
            guard let items = self.extensionContext?.inputItems as? [NSExtensionItem],
                  items.count > 0  else {
                return
            }
            for item in items {
                let attachments = item.attachments ?? []
                let count = attachments.count
                for itemProvider in attachments {
                    if itemProvider.hasItemConformingToTypeIdentifier("public.item") {
                        itemProvider.loadPreviewImage { _, _ in }
                        itemProvider.loadItem(forTypeIdentifier: "public.item") { url,_ in
                            
                            if let fileUrl = url as? URL,
                               let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: k_Send_file)?.path,
                               let filePaths = fileUrl.path.components(separatedBy: "/").last {
                                let urlt = URL.ReferenceType(fileURLWithPath:"\(path)/\(filePaths)")
        
                                if let filePath = urlt.path {
                                    try? FileManager.default.copyItem(at: fileUrl, to: urlt as URL)
                                    pathArray.append(filePath)
                                }
                            }
                            if count == pathArray.count {
                                DispatchQueue.main.async {
                                    let userDefaults = UserDefaults.init(suiteName: k_Send_file)
                                    userDefaults?.set(pathArray, forKey: k_Send_file_path)
                                    userDefaults?.setValue(true, forKey: k_Can_Send_file)
                                    userDefaults?.synchronize()
                                    
                                    var responder: UIResponder? = self as UIResponder
                                    let selector = Selector("openURL:")
                                    while responder != nil {
                                        if responder!.responds(to: selector) && responder != self {
                                            responder!.perform(selector, with:URL.init(string: k_SmartConnect_url) )
                                            self.extensionContext?.completeRequest(returningItems: []) { _ in }
                                            break
                                        }
                                        responder = responder?.next
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
