//
//  SLTCPManager.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/25.
//

import Foundation

public class SLTCPManager {
    private static let instance = SLTCPManager()
    
    private init() {}
    
    public static func shared() -> SLTCPManager {
        return instance
    }
    
    public func request(host: String, port: UInt16, msg: String, completion: @escaping ((_ result: SLResult<String, SLError>) -> Void)) {
        
    }
    
    public func asyncRequest(host: String, port: UInt16, taskId: String, text: String, timeout: SLTimeInterval = .seconds(30)) async throws -> Data {
        do {
            let socket = try await SLSocketManager.shared.asyncConnectServer(host: host, port: port, timeout: timeout)
            let data = try await SLSocketManager.shared.asyncSend(socket, text: text, timeout: timeout)
            return data
        } catch let error {
            throw error
        }
    }
}
