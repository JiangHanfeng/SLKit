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

class SLSocketDataHandlerProxy {
    let id: String
    var handler: SLSocketDataHandler? = nil
    
    init(id: String, handler: SLSocketDataHandler? = nil) {
        self.id = id
        self.handler = handler
    }
    
    deinit {
        print("\(self) with id(\(id)) deinit")
    }
}

public final class SLSocketManager: NSObject {
    static let socketQueue = DispatchQueue(label: "slkit.socketManager.queue")
    public static let shared = {
        let singleInstance = SLSocketManager()
        return singleInstance
    }()
    
    private var clients: [SLSocketClient:[SLSocketDataHandlerProxy]] = [:]
    
    private override init() {}
    
    private func getProxys(for sock: SLSocketClient, completion: @escaping((_ proxys: [SLSocketDataHandlerProxy]?) -> Void)) {
        Self.socketQueue.async {
            completion(self.clients[sock])
        }
    }
    
    private func update(proxys: [SLSocketDataHandlerProxy]?, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataHandlerProxy]?) -> Void)) {
        Self.socketQueue.async {
            if let proxys {
                self.clients.updateValue(proxys, forKey: sock)
            } else {
                self.clients.removeValue(forKey: sock)
            }
            completion(self.clients[sock])
        }
    }
    
    private func addProxy(_ proxy: SLSocketDataHandlerProxy, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataHandlerProxy]?) -> Void)) {
        getProxys(for: sock) { proxys in
            var newProxys = proxys
            newProxys?.append(proxy)
            self.update(proxys: newProxys, for: sock) { array in
                completion(array)
            }
        }
    }
     
    private func removeProxy(_ proxy: SLSocketDataHandlerProxy, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataHandlerProxy]?) -> Void)) {
        getProxys(for: sock) { proxys in
            var newProxys = proxys
            newProxys?.removeAll(where: { item in
                item.id.elementsEqual(proxy.id)
            })
            self.update(proxys: newProxys, for: sock) { array in
                completion(array)
            }
        }
    }
    
    @available(*, renamed: "getSocketClient(host:port:)")
    private func getSocketClient(host: String, port: UInt16, completion: @escaping ((_ socket: SLSocketClient) -> Void)) {
        Task {
            let result = await getSocketClient(host: host, port: port)
            completion(result)
        }
    }
    
    
    private func getSocketClient(host: String, port: UInt16) async -> SLSocketClient {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                if let socket = self.clients.keys.first(where: { item in
                    item.host.elementsEqual(host) && item.port == port
                }) {
                    continuation.resume(returning: socket)
                    return
                }
                let socket = SLSocketClient(host: host, port: port)
                self.clients.updateValue([], forKey: socket)
                continuation.resume(returning: socket)
            }
        }
    }
    
    @available(*, renamed: "connect(host:port:timeout:)")
    public func connect(host: String, port: UInt16, timeout: SLTimeInterval = .seconds(10), completion: @escaping ((SLResult<SLSocketClient, Error>) -> Void)) {
        Task {
            do {
                let result = try await connect(host: host, port: port, timeout: timeout)
                completion(.success(result))
            } catch let e {
                completion(.failure(e))
            }
        }
    }
    
    
    public func connect(host: String, port: UInt16, timeout: SLTimeInterval = .seconds(10)) async throws -> SLSocketClient {
        return try await withCheckedThrowingContinuation { continuation in
            self.getSocketClient(host: host, port: port) { socket in
                socket.startConnection(timeout: timeout) { [weak socket] result in
                    guard let socket else {
                        continuation.resume(throwing: SLError.socketDisconnected(nil))
                        return
                    }
                    switch result {
                    case .success(_):
                        socket.setReceivedDataHandler { [weak self] data in
                            if let proxys = self?.clients[socket] {
                                proxys.forEach { item in
                                    item.handler?(data)
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
    }
    
//    @available(*, renamed: "sendWithReponse(_:to:timeout:)")
//    public func sendWithReponse(_ data: Data, to sock: SLSocketClient, timeout: SLTimeInterval = .seconds(10), completion: @escaping ((SLResult<Data, Error>) -> Void)) {
//        Task {
//            let result = await sendWithReponse(data, to: sock, timeout: timeout)
//            completion(result)
//        }
//    }
//    
//    
//    public func sendWithReponse(_ data: Data, to sock: SLSocketClient, timeout: SLTimeInterval = .seconds(10)) async throws -> Data {
//        return try await withCheckedThrowingContinuation { continuation in
//            self.getSocketClient(host: sock.host, port: sock.port) { socket in
//                guard socket.isConnected else {
//                    continuation.resume(throwing: SLError.socketSendFailureNotConnected)
//                    return
//                }
//                guard !data.isEmpty else {
//                    continuation.resume(throwing: SLError.socketSendFailureEmptyData)
//                    return
//                }
//                do {
//                    try socket.send(data, timeout: timeout)
//                    let proxy = SLSocketDataHandlerProxy(id: request.id)
//                    self.getProxys(for: socket) { proxys in
//                        guard let proxys, !proxys.isEmpty else {
//                            continuation.resume(throwing: SLError.socketDisconnectedWaitingForResponse)
//                            return
//                        }
//                        proxy.handler = { [weak self, weak proxy] data in
//                            guard let self , let proxy else {
//                                continuation.resume(throwing: SLError.socketDisconnectedWaitingForResponse)
//                                return
//                            }
//                            do {
//                                let response = try U.init(data: data)
//                                if response.id.elementsEqual(request.id) {
//                                    self.removeProxy(proxy, for: socket) { array in
//                                        continuation.resume(returning: response)
//                                    }
//                                } else {
//                                    // wait until timeout
//                                    print("wait until response timeout")
//                                }
//                            } catch let error {
//                                self.removeProxy(proxy, for: socket) { array in
//                                    continuation.resume(throwing: error)
//                                }
//                            }
//                        }
//                        self.addProxy(proxy, for: socket) { array in
//                            
//                        }
//                    }
//                } catch let error {
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
    
    @available(*, renamed: "send(_:to:for:timeout:)")
    public func send<T: SLTCPSocketSessionItem, U: SLTCPSocketResponse>(_ request: T, to sock: SLSocketClient, for responseType: U.Type, timeout: SLTimeInterval = .seconds(10), completion: @escaping ((SLResult<U, Error>) -> Void)) {
        Task {
            do {
                let result = try await send(request, to: sock, for: responseType, timeout: timeout)
                completion(.success(result))
            } catch let e {
                completion(.failure(e))
            }
            
        }
    }
    
    
    public func send<T: SLTCPSocketSessionItem, U: SLTCPSocketResponse>(_ request: T, to sock: SLSocketClient, for responseType: U.Type, timeout: SLTimeInterval = .seconds(10)) async throws -> U {
        return try await withCheckedThrowingContinuation { continuation in
            self.getSocketClient(host: sock.host, port: sock.port) { socket in
                guard socket.isConnected else {
                    continuation.resume(throwing: SLError.socketSendFailureNotConnected)
                    return
                }
                guard let data = request.data, !data.isEmpty else {
                    continuation.resume(throwing: SLError.socketSendFailureEmptyData)
                    return
                }
                do {
                    try socket.send(data, timeout: timeout)
                    let proxy = SLSocketDataHandlerProxy(id: request.id)
                    self.getProxys(for: socket) { proxys in
                        guard let proxys, !proxys.isEmpty else {
                            continuation.resume(throwing: SLError.socketDisconnectedWaitingForResponse)
                            return
                        }
                        proxy.handler = { [weak self, weak proxy] data in
                            guard let self , let proxy else {
                                continuation.resume(throwing: SLError.socketDisconnectedWaitingForResponse)
                                return
                            }
                            do {
                                let response = try U.init(data: data)
                                if response.id.elementsEqual(request.id) {
                                    self.removeProxy(proxy, for: socket) { array in
                                        continuation.resume(returning: response)
                                    }
                                } else {
                                    // wait until timeout
                                    print("wait until response timeout")
                                }
                            } catch let error {
                                self.removeProxy(proxy, for: socket) { array in
                                    continuation.resume(throwing: error)
                                }
                            }
                        }
                        self.addProxy(proxy, for: socket) { array in
                            
                        }
                    }
                } catch let error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

