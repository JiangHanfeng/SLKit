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

struct SLSocketDataHandlerProxy {
    let tag: Int
    let handler: SLSocketDataHandler
}

public final class SLSocketManager: NSObject {
    static let socketQueue = DispatchQueue(label: "slkit.socketManager.queue")
    public static let shared = {
        let singleInstance = SLSocketManager()
        return singleInstance
    }()
    
    private var clients: [SLSocketClient:[SLSocketDataHandlerProxy]] = [:]
    
    private override init() {}
    
    public func getSocketClient(host: String, port: UInt16) -> SLSocketClient {
        if let socket = clients.keys.first(where: { item in
            item.host.elementsEqual(host) && item.port == port
        }) {
            return socket
        }
        let socket = SLSocketClient(host: host, port: port)
        clients.updateValue([], forKey: socket)
        return socket
    }
    
    public func asyncConnectServer(host: String, port: UInt16, timeout: SLTimeInterval = .seconds(15)) async throws -> SLSocketClient {
        let socket = getSocketClient(host: host, port: port)
        if socket.isConnected {
            return socket
        }
        return try await withCheckedThrowingContinuation { continuation in
            socket.startConnection(timeout: timeout) { result in
                switch result {
                case .success(_):
                    socket.setReceivedDataHandler { [weak self] data in
                        if let proxys = self?.clients[socket] {
                            proxys.forEach { item in
                                item.handler(data)
                            }
                        }
                    }
                    continuation.resume(returning: socket)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func asyncSend(_ socket: SLSocketClient, text: String, timeout: SLTimeInterval = .seconds(15)) async throws -> Data {
        do {
            try socket.send(text, timeout: timeout)
            return try await withCheckedThrowingContinuation { continuation in
                if var arr1 = self.clients[socket] {
                    let tag = arr1.count - 1
                    let proxy = SLSocketDataHandlerProxy(tag: tag) { [weak self] data in
                        if var arr2 = self?.clients[socket] {
                            arr2.removeAll { item in
                                item.tag == tag
                            }
                            self?.clients.updateValue(arr2, forKey: socket)
                            continuation.resume(returning: data)
                        } else {
                            continuation.resume(throwing: SLError.socketNotConnectedYet)
                        }
                    }
                    arr1.append(proxy)
                    self.clients.updateValue(arr1, forKey: socket)
                } else {
                    continuation.resume(throwing: SLError.socketNotConnectedYet)
                }
            }
        } catch let error {
            throw error
        }
    }
}
