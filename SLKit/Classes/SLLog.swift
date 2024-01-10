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
        let date = Date()
        let  dateFormater = DateFormatter.init()
        dateFormater.dateFormat = "YY年MM月dd日HH时mm分ss秒"
        let dateString = dateFormater.string(from: date)
        let docsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)
        let docsDir = docsPaths.first ?? ""
        let filePath = "\(docsDir)/log_\(dateString).txt"
        let fileManager = FileManager()
        do {
            let arr = try fileManager.contentsOfDirectory(atPath: docsDir).reversed().filter { item in
                item.elementsEqual("sl_log.txt") || item.starts(with: "log_")
            }
            
            let logFileCountMaxAllowed = 10
            print("当前log日志个数：\(arr.count)，允许最大日志个数：\(logFileCountMaxAllowed)")
            var deleted = 0
            if arr.count > logFileCountMaxAllowed {
                for logFileNameNeedDelete in arr[logFileCountMaxAllowed..<arr.count] {
                    let logFilePathNeedDelete = docsDir + "/\(logFileNameNeedDelete)"
                    try fileManager.removeItem(atPath: logFilePathNeedDelete)
                    deleted += 1
                }
                print("已成功删除日志个数：\(deleted)")
            }
            
        } catch let e {
            print("try delete log file exception:\n\(e.localizedDescription)")
        }
        
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
