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
    
    /// 获取某个socket的数据响应处理集合
    @available(*, renamed: "getProxys(for:)")
    private func getProxys(for sock: SLSocketClient, completion: @escaping((_ proxys: [SLSocketDataHandlerProxy]?) -> Void)) {
        Task {
            let result = await getProxys(for: sock)
            completion(result)
        }
    }
    
    /// 获取某个socket的数据响应处理集合
    private func getProxys(for sock: SLSocketClient) async -> [SLSocketDataHandlerProxy]? {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                continuation.resume(returning: self.clients[sock])
            }
        }
    }
    
    /// 更新某个socket的数据响应处理集合
    @available(*, renamed: "update(proxys:for:)")
    private func update(proxys: [SLSocketDataHandlerProxy]?, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataHandlerProxy]?) -> Void)) {
        Task {
            let result = await update(proxys: proxys, for: sock)
            completion(result)
        }
    }
    
    /// 更新某个socket的数据响应处理集合
    private func update(proxys: [SLSocketDataHandlerProxy]?, for sock: SLSocketClient) async -> [SLSocketDataHandlerProxy]? {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                if let proxys {
                    self.clients.updateValue(proxys, forKey: sock)
                } else {
                    self.clients.removeValue(forKey: sock)
                }
                continuation.resume(returning: self.clients[sock])
            }
        }
    }
    
    /// 为某个socket添加新的数据响应的处理
    @available(*, renamed: "addProxy(_:for:)")
    private func addProxy(_ proxy: SLSocketDataHandlerProxy, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataHandlerProxy]?) -> Void)) {
        Task {
            let result = await addProxy(proxy, for: sock)
            completion(result)
        }
    }
    
    /// 为某个socket添加新的数据响应的处理
    private func addProxy(_ proxy: SLSocketDataHandlerProxy, for sock: SLSocketClient) async -> [SLSocketDataHandlerProxy]? {
        let proxys = await getProxys(for: sock)
        var newProxys = proxys
        newProxys?.append(proxy)
        let array = await self.update(proxys: newProxys, for: sock)
        return array
    }
    
    /// 移除某个socket的特定的数据响应处理
    @available(*, renamed: "removeProxy(_:for:)")
    private func removeProxy(_ proxy: SLSocketDataHandlerProxy, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataHandlerProxy]?) -> Void)) {
        Task {
            let result = await removeProxy(proxy, for: sock)
            completion(result)
        }
    }
    
    /// 移除某个socket的特定的数据响应处理
    private func removeProxy(_ proxy: SLSocketDataHandlerProxy, for sock: SLSocketClient) async -> [SLSocketDataHandlerProxy]? {
        let proxys = await getProxys(for: sock)
        var newProxys = proxys
        newProxys?.removeAll(where: { item in
            item.id.elementsEqual(proxy.id)
        })
        let array = await self.update(proxys: newProxys, for: sock)
        return array
    }
    
    /// 根据ip和端口获取socket
    @available(*, renamed: "getSocketClient(host:port:)")
    private func getSocketClient(host: String, port: UInt16, completion: @escaping ((_ socket: SLSocketClient?) -> Void)) {
        Task {
            let result = await getSocketClient(host: host, port: port)
            completion(result)
        }
    }
    
    /// 根据ip和端口获取socket
    private func getSocketClient(host: String, port: UInt16) async -> SLSocketClient? {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                if let socket = self.clients.keys.first(where: { item in
                    item.host.elementsEqual(host) && item.port == port
                }) {
                    continuation.resume(returning: socket)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// 添加socket
    @available(*, renamed: "addSocketClient(_:)")
    private func addSocketClient(_ sock: SLSocketClient, completion: @escaping (() -> Void)) {
        Task {
            await addSocketClient(sock)
            completion()
        }
    }
    
    /// 添加socket
    private func addSocketClient(_ sock: SLSocketClient) async {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                if nil == self.clients[sock] {
                    self.clients.updateValue([], forKey: sock)
                }
                continuation.resume(returning: ())
            }
        }
    }
    
    /// 删除socket
    @available(*, renamed: "removeSocket(_:)")
    private func removeSocket(_ sock: SLSocketClient, completion: @escaping (() -> Void)) {
        Task {
            await removeSocket(sock)
            completion()
        }
    }
    
    /// 删除socket
    private func removeSocket(_ sock: SLSocketClient) async {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                self.clients.removeValue(forKey: sock)
                continuation.resume(returning: ())
            }
        }
    }
    
    /// 连接
    @available(*, renamed: "connect(host:port:timeout:)")
    public func connect(host: String, port: UInt16, timeout: SLTimeInterval = .seconds(10), heartbeatRule: SLSocketHeartbeatRule? = nil, completion: @escaping ((SLResult<SLSocketClient, Error>) -> Void)) {
        Task {
            do {
                let result = try await connect(host: host, port: port, timeout: timeout, heartbeatRule: heartbeatRule)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch let e {
                DispatchQueue.main.async {
                    completion(.failure(e))
                }
            }
        }
    }
    
    /// 连接
    public func connect(host: String, port: UInt16, timeout: SLTimeInterval = .seconds(10), heartbeatRule: SLSocketHeartbeatRule? = nil) async throws -> SLSocketClient {
        print("连接socket:\(host):\(port)")
        var sock = await getSocketClient(host: host, port: port)
        if sock == nil {
            sock = SLSocketClient(host: host, port: port, heartbeatRule: heartbeatRule)
            await addSocketClient(sock!)
        }
        return try await withCheckedThrowingContinuation { continuation in
            sock?.startConnection(timeout: timeout) { [weak socket = sock] result in
                guard let socket else {
                    continuation.resume(throwing: SLError.socketHasBeenReleased)
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
    
    /// 取消连接
    @available(*, renamed: "cancelConnect(host:port:)")
    public func cancelConnect(host: String, port: UInt16, completion: @escaping (() -> Void)) {
        getSocketClient(host: host, port: port) { socket in
            if let socket {
                socket.disconnect()
                self.clients.removeValue(forKey: socket)
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    /// 取消连接
    public func cancelConnect(host: String, port: UInt16) async {
        return await withCheckedContinuation { contiuation in
            self.cancelConnect(host: host, port: port) {
                contiuation.resume()
            }
        }
    }
    
    /// 断开连接
    @available(*, renamed: "disconnect(_:)")
    public func disconnect(_ sock: SLSocketClient, completion: @escaping (() -> Void)) {
        Task {
            await disconnect(sock)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    /// 断开连接
    public func disconnect(_ sock: SLSocketClient) async {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                sock.disconnect()
                self.clients.removeValue(forKey: sock)
                continuation.resume(returning: ())
            }
        }
    }
    
    /// 发送二进制
    public func send(_ data: Data, to sock: SLSocketClient, timeout: SLTimeInterval = .seconds(10)) throws {
        do {
            try sock.send(data, timeout: timeout)
        } catch let e {
            throw e
        }
    }
    
    /// 发送字符串
    public func send(_ text: String, to sock: SLSocketClient, timeout: SLTimeInterval = . seconds(10)) throws {
        do {
            try sock.send(text, timeout: timeout)
        } catch let e {
            throw e
        }
    }
    
    /// 发送请求，并指定响应类型
    @available(*, renamed: "send(_:to:for:timeout:)")
    public func send<T: SLSocketSessionItem, U: SLSocketResponse>(_ request: T, to sock: SLSocketClient, for responseType: U.Type, timeout: SLTimeInterval = .seconds(10), completion: @escaping ((SLResult<U, Error>) -> Void)) {
        Task {
            do {
                let result = try await send(request, to: sock, for: responseType, timeout: timeout)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch let e {
                DispatchQueue.main.async {
                    completion(.failure(e))
                }
            }
        }
    }
    
    /// 发送请求，并指定响应类型
    public func send<T: SLSocketSessionItem, U: SLSocketResponse>(_ request: T, to sock: SLSocketClient, for responseType: U.Type, timeout: SLTimeInterval = .seconds(10)) async throws -> U {
        return try await withCheckedThrowingContinuation { continuation in
            self.getSocketClient(host: sock.host, port: sock.port) { socket in
                guard let socket, socket.isConnected else {
                    continuation.resume(throwing: SLError.socketSendFailureNotConnected)
                    return
                }
                guard let data = request.data, !data.isEmpty else {
                    continuation.resume(throwing: SLError.socketSendFailureEmptyData)
                    return
                }
                let proxy = SLSocketDataHandlerProxy(id: request.id)
                self.getProxys(for: socket) { proxys in
                    guard let proxys else {
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
                                // MARK: wait until socket write and receive timeout
                                print("wait until socket write and receive timeout")
                            }
                        } catch let error {
                            // MARK: 还需要优化当socket返回无法序列化的数据时，如何从data中取出id进行对应的响应处理，否则会出现异常不匹配的bug，比如如果socket把心跳数据抛到这一层的话，就大概率会出现请求A刚发送完就因为收到心跳响应，而心跳响应无法解析成期望的返回类型，请求就被提前终止了，问题的关键在于data和id的关联方法是交给上层处理的，实际上应该在内部生成，可以考虑socket发送数据时的tag
                            self.removeProxy(proxy, for: socket) { array in
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                    self.addProxy(proxy, for: socket) { array in
                        do {
                            try socket.send(data, timeout: timeout)
                        } catch let e {
                            continuation.resume(throwing: e)
                        }
                    }
                }
            }
        }
    }
}

