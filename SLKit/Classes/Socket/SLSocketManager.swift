//
//  SLSocketManager.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/19.
//

import Foundation
import CocoaAsyncSocket
//import RxCocoa
//import RxSwift

//protocol SLSocketUnhandledDataProcesser {
//    associatedtype ExpectDataType
//    var process: ((_ data: ExpectDataType) -> Void) { get }
//}

public final class SLSocketUnhandledDataProcesser<T: SLSocketDataMapper> {
    public var process: ((T) -> Void)
    
    init(process: @escaping (T) -> Void) {
        self.process = process
    }
}

public typealias SLSocketDataResponseHandlerAction = ((Data) -> Bool)

class SLSocketDataResponseHandler {
    let id: String
    var handle: SLSocketDataResponseHandlerAction? = nil
    private var interruptHandler: (() -> Void)?
    private var timeoutChecker: SLCancelableWork?
    private var completed: Bool?
    
    init(id: String, handle: SLSocketDataResponseHandlerAction? = nil, interrupted: @escaping (() -> Void)) {
        self.id = id
        self.handle = handle
        self.interruptHandler = interrupted
    }
    
    func start(timeout: SLTimeInterval, timeoutHandler: @escaping (() -> Void)) {
        completed = false
        timeoutChecker?.cancel()
        timeoutChecker = nil
        switch timeout {
        case .infinity:
            break
        case .seconds(let timeout):
            timeoutChecker = SLCancelableWork(id: self.id, delayTime: .seconds(Int(timeout)), closure: { [weak self] in
                if let completed = self?.completed, !completed {
                    self?.completed = true
                    SLLog.debug("socket data handler(id: \(self?.id ?? "")) timeout")
                    // 超时
                    timeoutHandler()
                }
            })
            timeoutChecker?.start(at: DispatchQueue.global())
        }
    }
    
    func finished() {
        completed = true
    }
    
    deinit {
        if let completed, !completed {
            self.completed = true
            interruptHandler?()
        }
        print("\(self) with id(\(id)) deinit")
    }
}

class SLSocketDataHandler<T: SLSocketDataMapper> {
    var responseHandler: SLSocketDataResponseHandler?
    var unhandledDataHandler: SLSocketUnhandledDataProcesser<T>?
}

public class SLSocketClientUnhandledDataHandler {
    let id: String
    let handle: (_ data: Data, _ from: SLSocketClient?) -> Void
    
    public init(id: String, handle: @escaping (_: Data, _: SLSocketClient?) -> Void) {
        self.id = id
        self.handle = handle
    }
}

public final class SLSocketManager: NSObject {
    
    static let socketQueue = DispatchQueue(label: "slkit.socketManager.queue")
    
    public static let shared = {
        let singleInstance = SLSocketManager()
        return singleInstance
    }()
    
    private var clients: [SLSocketClient:[SLSocketDataResponseHandler]] = [:]
    
    private var servers: [SLSocketServer:[SLSocketDataResponseHandler]] = [:]
    
    private var unhandledDataHandlers: [SLSocketClientUnhandledDataHandler] = []
    
    private override init() {}
    
    /// 获取某个socket client的数据响应处理集合
    @available(*, renamed: "getProxys(for:)")
    private func getProxys(for sock: SLSocketClient, completion: @escaping((_ proxys: [SLSocketDataResponseHandler]?) -> Void)) {
        Task {
            let result = await getProxys(for: sock)
            completion(result)
        }
    }
    
    /// 获取某个socket的数据响应处理集合
    private func getProxys(for sock: SLSocketClient) async -> [SLSocketDataResponseHandler]? {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                continuation.resume(returning: self.clients[sock])
            }
        }
    }
    
    /// 更新某个socket的数据响应处理集合
    @available(*, renamed: "update(proxys:for:)")
    private func update(proxys: [SLSocketDataResponseHandler]?, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataResponseHandler]?) -> Void)) {
        Task {
            let result = await update(proxys: proxys, for: sock)
            completion(result)
        }
    }
    
    /// 更新某个socket的数据响应处理集合
    private func update(proxys: [SLSocketDataResponseHandler]?, for sock: SLSocketClient) async -> [SLSocketDataResponseHandler]? {
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
    private func addProxy(_ proxy: SLSocketDataResponseHandler, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataResponseHandler]?) -> Void)) {
        Task {
            let result = await addProxy(proxy, for: sock)
            completion(result)
        }
    }
    
    /// 为某个socket添加新的数据响应的处理
    private func addProxy(_ proxy: SLSocketDataResponseHandler, for sock: SLSocketClient) async -> [SLSocketDataResponseHandler]? {
        let proxys = await getProxys(for: sock)
        var newProxys = proxys
        newProxys?.append(proxy)
        let array = await self.update(proxys: newProxys, for: sock)
        return array
    }
    
    /// 移除某个socket的特定的数据响应处理
    @available(*, renamed: "removeProxy(_:for:)")
    private func removeProxy(_ proxy: SLSocketDataResponseHandler, for sock: SLSocketClient, completion: @escaping ((_ array: [SLSocketDataResponseHandler]?) -> Void)) {
        Task {
            let result = await removeProxy(proxy, for: sock)
            completion(result)
        }
    }
    
    /// 移除某个socket的特定的数据响应处理
    private func removeProxy(_ proxy: SLSocketDataResponseHandler, for sock: SLSocketClient) async -> [SLSocketDataResponseHandler]? {
        let proxys = await getProxys(for: sock)
        var newProxys = proxys
        newProxys?.removeAll(where: { item in
            item.id.elementsEqual(proxy.id)
        })
        let array = await self.update(proxys: newProxys, for: sock)
        return array
    }
    
    /// 根据ip和端口获取socket client
    @available(*, renamed: "getSocketClient(host:port:)")
    private func getSocketClient(host: String, port: UInt16, completion: @escaping ((_ socket: SLSocketClient?) -> Void)) {
        Task {
            let result = await getSocketClient(host: host, port: port)
            completion(result)
        }
    }
    
    /// 根据ip和端口获取socket client
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
    
    /// 根据端口获取socket server
    @available(*, renamed: "getSocketServer(port:)")
    private func getSocketServer(port: UInt16, completion: @escaping ((_ socket: SLSocketServer?) -> Void)) {
        Task {
            let result = await getSocketServer(port: port)
            completion(result)
        }
    }
    
    /// 根据端口获取socket server
    private func getSocketServer(port: UInt16) async -> SLSocketServer? {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                if let socket = self.servers.keys.first(where: { item in
                    item.port == port
                }) {
                    continuation.resume(returning: socket)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// 添加socket client
    @available(*, renamed: "addSocketClient(_:)")
    private func addSocketClient(_ sock: SLSocketClient, completion: @escaping (() -> Void)) {
        Task {
            await addSocketClient(sock)
            completion()
        }
    }
    
    /// 添加socket client
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
    
    /// 删除socket client
    @available(*, renamed: "removeSocketClient(_:)")
    private func removeSockeClient(_ sock: SLSocketClient, completion: @escaping (() -> Void)) {
        Task {
            await removeSocketClient(sock)
            completion()
        }
    }
    
    /// 删除socket client
    private func removeSocketClient(_ sock: SLSocketClient) async {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                self.clients.removeValue(forKey: sock)
                continuation.resume(returning: ())
            }
        }
    }
    
    /// 添加socket server
    @available(*, renamed: "addSocketServer(_:)")
    private func addSocketServer(_ sock: SLSocketServer, completion: @escaping (() -> Void)) {
        Task {
            await addSocketServer(sock)
            completion()
        }
    }
    
    /// 添加socket server
    private func addSocketServer(_ sock: SLSocketServer) async {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                if nil == self.servers[sock] {
                    self.servers.updateValue([], forKey: sock)
                }
                continuation.resume(returning: ())
            }
        }
    }
    
    /// 删除socket server
    @available(*, renamed: "removeSocketServer(_:)")
    private func removeSocketServer(_ sock: SLSocketServer, completion: @escaping (() -> Void)) {
        Task {
            await removeSocketServer(sock)
            completion()
        }
    }
    
    /// 删除socket server
    private func removeSocketServer(_ sock: SLSocketServer) async {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                self.servers.removeValue(forKey: sock)
                continuation.resume(returning: ())
            }
        }
    }
    
    /// 监听
    @available(*, renamed: "startListen(port:gateway:heartbeatRule:)")
    public func startListen(port: UInt16, gateway: SLSocketServerGateway, heartbeatRule: SLSocketHeartbeatRule? = nil, completion: @escaping ((SLResult<SLSocketServer, Error>) -> Void)) {
        Task {
            do {
                let result = try await startListen(port: port, gateway: gateway, heartbeatRule: heartbeatRule)
                completion(.success(result))
            } catch let e {
                completion(.failure(e))
            }
        }
    }
    
    /// 监听
    public func startListen(port: UInt16, gateway: SLSocketServerGateway, heartbeatRule: SLSocketHeartbeatRule? = nil) async throws -> SLSocketServer {
        return try await withCheckedThrowingContinuation { continuation in
            self.getSocketServer(port: port) { socket in
                var sock = socket
                let configSock: ((SLSocketServer) -> Void) = { s in
                    s.startListen(completion: { error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            s.dataHandler = { [weak self, weak serverSocket = s] data in
                                if let serverSocket, let proxys = self?.servers[serverSocket] {
                                    proxys.forEach { item in
                                        item.handle?(data)
                                    }
                                }
                            }
                            continuation.resume(returning: s)
                        }
                    })
                }
                if sock == nil {
                    sock = SLSocketServer(port: port, gateway: gateway, hearbeatRule: heartbeatRule)
                    self.addSocketServer(sock!) {
                        configSock(sock!)
                    }
                } else {
                    configSock(sock!)
                }
            }
        }
    }
    
    @available(*, renamed: "stopListen(_:)")
    public func stopListen(_ sock: SLSocketServer, completion: @escaping (() -> Void)) {
        Task {
            await stopListen(sock)
            completion()
        }
    }
    
    
    public func stopListen(_ sock: SLSocketServer) async {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                sock.stopListen()
                self.removeSocketServer(sock) {
                    continuation.resume()
                }
            }
        }
    }
    
    @available(*, renamed: "stopListen(port:)")
    public func stopListen(port: UInt16, completion: @escaping (() -> Void)) {
        Task {
            await stopListen(port: port)
            completion()
        }
    }
    
    
    public func stopListen(port: UInt16) async {
        return await withCheckedContinuation { continuation in
            Self.socketQueue.async {
                self.getSocketServer(port: port) { socket in
                    if let socket {
                        self.stopListen(socket) {
                            continuation.resume()
                        }
                    } else {
                        continuation.resume()
                    }
                }
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
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: SLError.socketHasBeenReleased)
                return
            }
            self.getSocketClient(host: host, port: port) { socket in
                var sock = socket
                let configSock: ((SLSocketClient) -> Void) = {
                    $0.startConnection(timeout: timeout) { [weak socket = $0] result in
                        guard let socket else {
                            continuation.resume(throwing: SLError.socketHasBeenReleased)
                            return
                        }
                        switch result {
                        case .success(_):
                            socket.dataHandler = { [weak manager = self, weak thisSock = socket] data in
                                var dataHandled = false
                                if let manager, let thisSock, let proxys = manager.clients[thisSock] {
                                    for item in proxys {
                                        let result = item.handle?(data)
                                        item.finished()
                                        if result == true {
                                            dataHandled = true
                                            break
                                        }
                                    }
                                }
                                if !dataHandled {
                                    // 未被处理的数据
                                    manager?.unhandledDataHandlers.forEach({ item in
                                        item.handle(data, thisSock)
//                                        item.handle(data, socket)
                                    })
                                }
                            }
                            continuation.resume(returning: socket)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                if sock == nil {
                    sock = SLSocketClient(host: host, port: port, heartbeatRule: heartbeatRule)
                    self.addSocketClient(sock!) {
                        configSock(sock!)
                    }
                } else {
                    configSock(sock!)
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
        return await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(returning: ())
                return
            }
            self.removeSockeClient(sock) {
                sock.disconnect()
                continuation.resume(returning: ())
            }
//            Self.socketQueue.async {
//                sock.disconnect()
//                
//                self.clients.removeValue(forKey: sock)
//                
//            }
        }
    }
    
    /// 发送二进制
    public func send(_ data: Data, to sock: SLSocketClient, timeout: SLTimeInterval = .seconds(10)) throws {
        do {
            try sock.send(data, type: 0x11, timeout: timeout)
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
    
    /// 从某个socket client发送请求，无需响应
    public func send<T: SLSocketRequest>(request: T, from sock: SLSocketClient, completion: @escaping ((SLResult<Void, Error>) -> Void)) {
        self.getSocketClient(host: sock.host, port: sock.port) { socket in
            let mainQueue = DispatchQueue.main
            guard let socket, socket.isConnected else {
                mainQueue.async {
                    completion(.failure(SLError.socketSendFailureNotConnected))
                }
                return
            }
            guard let data = request.data, !data.isEmpty else {
                mainQueue.async {
                    completion(.failure(SLError.socketSendFailureEmptyData))
                }
                return
            }
            do {
                try socket.send(data, type: request.type.rawValue)
                mainQueue.async {
                    completion(.success(()))
                }
            } catch let e {
                mainQueue.async {
                    completion(.failure(e))
                }
            }
        }
    }
    
    /// 从某个socket client发送请求，并指定响应类型
    @available(*, renamed: "send(_:from:for:timeout:)")
    public func send<T: SLSocketRequest, U: SLSocketDataMapper>(_ request: T, from sock: SLSocketClient, for responseType: U.Type, timeout: SLTimeInterval = .seconds(10), completion: @escaping ((SLResult<U, Error>) -> Void)) {
        Task {
            do {
                let result = try await send(request, from: sock, for: responseType, timeout: timeout)
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
    
    /// 从某个socket client发送请求，并指定响应类型
    public func send<T: SLSocketRequest, U: SLSocketDataMapper>(_ request: T, from client: SLSocketClient, for responseType: U.Type, timeout: SLTimeInterval = .seconds(10)) async throws -> U {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: SLError.socketHasBeenReleased)
                return
            }
            self.getSocketClient(host: client.host, port: client.port) { socket in
                guard let socket, socket.isConnected else {
                    continuation.resume(throwing: SLError.socketSendFailureNotConnected)
                    return
                }
                guard let data = request.data, !data.isEmpty else {
                    continuation.resume(throwing: SLError.socketSendFailureEmptyData)
                    return
                }
                // 为本次请求生成一个数据处理
                let proxy = SLSocketDataResponseHandler(id: request.id) {
                    continuation.resume(throwing: SLError.taskCanceled)
                }
                proxy.handle = { [weak manager = self, weak proxy] data in
                    guard let proxy else {
                        continuation.resume(throwing: SLError.socketDisconnectedWaitingForResponse)
                        return false
                    }
                    do {
                        let response = U.init(data: data)
                        if response.id.elementsEqual(request.id) {
                            manager?.removeProxy(proxy, for: socket) { array in
                                continuation.resume(returning: response)
                            }
                            return true
                        } else {
                            // MARK: wait until socket write and receive timeout
                            SLLog.debug("wait until socket write and receive timeout with request id : \(request.id)")
                            return false
                        }
                    }
                }
                self.getProxys(for: socket) { proxys in
                    guard proxys != nil else {
                        continuation.resume(throwing: SLError.socketDisconnectedWaitingForResponse)
                        return
                    }
                    self.addProxy(proxy, for: socket) { array in
                        do {
                            try socket.send(data, type: request.type.rawValue, timeout: timeout)
                            proxy.start(timeout: timeout) {
                                continuation.resume(throwing: SLError.taskTimeout)
                            }
                        } catch let e {
                            continuation.resume(throwing: e)
                        }
                    }
                }
            }
        }
    }
    
    /// 监听从远端socket client收到的未处理的数据
    public func addHandlerToProcessUnhandledData<T>(of client: SLSocketClient, expectDataType: T.Type, handler: SLSocketUnhandledDataProcesser<T>) {
        
    }
    
    public func addClientUnhandledDataHandler(_ handler: SLSocketClientUnhandledDataHandler) {
        unhandledDataHandlers.append(handler)
    }
    
    public func removeClientUnhandledDataHandler(_ handler: SLSocketClientUnhandledDataHandler) {
        unhandledDataHandlers.removeAll { item in
            item.id.elementsEqual(handler.id)
        }
    }
}
