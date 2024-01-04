//
//  StringExtension.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/14.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation

extension String {
    func ipV4Bytes() -> [UInt8]? {
        let arr = split(separator: ".")
        guard arr.count == 4 else {
            return nil
        }
        var bytes: [UInt8] = []
        for i in arr {
            if let uint8 = UInt8(String(i)) {
                bytes.append(uint8)
            } else {
                break
            }
        }
        guard bytes.count == 4 else {
            return nil
        }
        return bytes
    }
    
    func macBytes() -> [UInt8]? {
        let arr = split(separator: ":")
        guard arr.count == 6 else {
            return nil
        }
        var bytes: [UInt8] = []
        for i in arr {
            let scanner = Scanner(string: String(i))
            var macSegment: UInt64 = 0
            scanner.scanHexInt64(&macSegment)
            if let uint8 = UInt8(exactly: macSegment) {
                bytes.append(uint8)
            } else {
                break
            }
        }
        guard bytes.count == 6 else {
            return nil
        }
        return bytes
    }
    
    func hex2IpV4() -> [UInt8]? {
        guard count == 8 else {
            return nil
        }
        var ipV4: [UInt8] = []
        for i in 0...3 {
            let j = self.index(startIndex, offsetBy: i * 2)
            let k = self.index(startIndex, offsetBy: i * 2 + 2)
            let hexStr = String(self[j..<k])
            let scanner = Scanner(string: hexStr)
            var ipSegment: UInt64 = 0
            scanner.scanHexInt64(&ipSegment)
            if let int8 = UInt8(exactly: ipSegment) {
                ipV4.append(int8)
            }
        }
        return ipV4
    }
    
    func hex2Port() -> UInt16? {
        guard count < 5 else {
            return nil
        }
        let scanner = Scanner(string: self)
        var port: UInt64 = 0
        scanner.scanHexInt64(&port)
        return UInt16(exactly: port)
    }
    
    func hex2Mac() -> [UInt8]? {
        guard count == 12 else {
            return nil
        }
        var macAddress: [UInt8] = []
        for i in 0...5 {
            let j = self.index(startIndex, offsetBy: i * 2)
            let k = self.index(startIndex, offsetBy: i * 2 + 2)
            let hexStr = String(self[j..<k])
            let scanner = Scanner(string: hexStr)
            var macSegment: UInt64 = 0
            scanner.scanHexInt64(&macSegment)
            if let int8 = UInt8(exactly: macSegment) {
                macAddress.append(int8)
            }
        }
        return macAddress
    }
}
