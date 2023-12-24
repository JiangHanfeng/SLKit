//
//  SLLog.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/1.
//

import Foundation
import XCGLogger

public class SLLog {
    public static func prepare() {
#if APPSTORE
#else
        let docsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)
        let docsDir = docsPaths.first ?? ""
        let filePath = "\(docsDir)/sl_log.txt"
        
        //日志对象设置
        XCGLogger.default.setup(level: .debug,
                                showThreadName: true,
                                showLevel: true,
                                showFileNames: true,
                                showLineNumbers: true,
                                writeToFile: filePath,
                                fileLevel: .debug)
        
#endif
    }
    
    public static func debug(_ text: String){
        XCGLogger.default.debug(text)
    }
    
    private init() {}
}
