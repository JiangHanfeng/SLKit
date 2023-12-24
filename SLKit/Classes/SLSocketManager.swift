//
//  SLSocketManager.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/19.
//

import Foundation
import CocoaAsyncSocket
import RxCocoa
import RxSwift

public final class SLSocketManager: NSObject {
    static let socketQueue = DispatchQueue(label: "slkit.socketManager.queue")
    public static let shared = {
        let singleInstance = SLSocketManager()
        return singleInstance
    }()
    
    private var clients: [SLSocketClient] = []
    
    private override init() {}
    
    public func getSocketClient(host: String, port: UInt16) -> SLSocketClient {
        if let socket = clients.first(where: { item in
            item.host.elementsEqual(host) && item.port == port
        }) {
            return socket
        }
        clients.append(SLSocketClient(host: host, port: port))
        return clients.last!
    }
    
    public func asyncConnectServer(host: String, port: UInt16, timeout: SLTimeInterval = .seconds(15)) async throws -> SLSocketClient {
        let socket = getSocketClient(host: host, port: port)
        return try await withCheckedThrowingContinuation { continuation in
            socket.startConnection(timeout: timeout) { result in
                switch result {
                case .success(_):
                    continuation.resume(returning: socket)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
