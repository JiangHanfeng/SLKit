//
//  SLSocketServer.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/29.
//

import Foundation
import CocoaAsyncSocket
import RxSwift

public struct SLAcceptedSocket : Equatable {
    public let host: String?
    public let port: UInt16
    let socket: GCDAsyncSocket
    
    init(host: String?, port: UInt16, socket: GCDAsyncSocket) {
        self.host = host
        self.port = port
        self.socket = socket
    }
    
    public static func == (lhs: SLAcceptedSocket, rhs: SLAcceptedSocket) -> Bool {
        return (lhs.host ?? "").elementsEqual(rhs.host ?? "") && lhs.port == rhs.port && lhs.socket.isEqual(rhs.socket)
    }
}

public enum SLSocketServerAuthrizationResult {
    case access(Data?)
    case deny(Data?)
}

public struct SLSocketServerGateway {
    public let connectionAuthrizationHandler: ((_ sock: SLAcceptedSocket, _ connectionCount: Int) -> SLSocketServerAuthrizationResult)
    public let dataAuthrizationHandler: ((_ sock: SLAcceptedSocket, _ data: Data) -> SLSocketServerAuthrizationResult)
    
    public init(
        connectionAuthrizationHandler: @escaping ((SLAcceptedSocket, Int) -> SLSocketServerAuthrizationResult),
        dataAuthrizationHandler: @escaping ((SLAcceptedSocket, Data) -> SLSocketServerAuthrizationResult)
    ) {
        self.connectionAuthrizationHandler = connectionAuthrizationHandler
        self.dataAuthrizationHandler = dataAuthrizationHandler
    }
}

public class SLSocketServer : NSObject {

    public enum State {
        case initilized
        case listening
        case connected
        case disconnectedUnexpected
    }
    
    fileprivate static let queue = DispatchQueue(label: (Bundle.main.bundleIdentifier ?? "com") + ".slkit.socket.server")
    
    public let port: UInt16
    public let gateway: SLSocketServerGateway
    
    private var state: State!
    
    public let heartbeatRule: SLSocketHeartbeatRule?
    
    fileprivate var connectionCompletion: ((SLResult<Void, SLError>) -> Void)?
    
    public var unexpectedDisconnectHandler: ((SLError?) -> Void)?
    
    fileprivate var server: GCDAsyncSocket?
    fileprivate var acceptedClients: [SLAcceptedSocket] = []
    fileprivate var currentClient: SLAcceptedSocket?
    
    fileprivate var currentClientDesc : String? {
        get {
            return currentClient != nil ? "\(currentClient!.host ?? "nil host"):\(currentClient!.port)" : nil
        }
    }
    
    public var dataHandler: SLSocketDataHandler?
    
    private var heartbeatTimer: Timer?
    
    private var lastReadTime: TimeInterval?
    
    private var heartbeatTimeoutChecker: SLCancelableWork?
    
    private var cachedData: Data?
    
    public var isConnected : Bool {
        return currentClient?.socket.isConnected ?? false
    }
    
    public func getState() -> SLSocketServer.State {
        return state
    }
    
    public init(port: UInt16, gateway: SLSocketServerGateway, hearbeatRule: SLSocketHeartbeatRule? = nil) {
        self.port = port
        self.gateway = gateway
        self.heartbeatRule = hearbeatRule
        self.state = .initilized
    }
    
    public func startListen(completion: @escaping ((SLError?) -> Void)) {
        Self.queue.async {
            if let _ = self.server, self.state == .listening {
                completion(nil)
                return
            }
            if self.server == nil {
                self.server = GCDAsyncSocket(delegate: self, delegateQueue: Self.queue)
            }
            if self.state == .initilized || self.state == .disconnectedUnexpected {
                do {
                    self.state = .listening
                    try self.server!.accept(onPort: self.port)
                    completion(nil)
                } catch let e {
                    self.state = .initilized
                    completion(SLError.socketListenFailure(e))
                }
            } else {
                completion(SLError.socketWrongServerState)
            }
        }
    }
    
    public func stopListen() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        heartbeatTimeoutChecker?.cancel()
        heartbeatTimeoutChecker = nil
        state = .initilized
        server?.disconnect()
        acceptedClients.removeAll()
        currentClient = nil
        cachedData = nil
    }
    
    public func send(_ text: String, timeout: SLTimeInterval = .seconds(15)) throws {
        guard let data = text.data(using: .utf8), data.count > 0 else {
            throw SLError.socketSendFailureDataError
        }
        do {
            try send(data, timeout: timeout)
        } catch let error {
            throw error
        }
    }
    
    public func send(_ data: Data, timeout: SLTimeInterval = .seconds(15)) throws {
        guard let socket = server, socket.isConnected else {
            throw SLError.socketSendFailureNotConnected
        }
        var time = TimeInterval.infinity
        switch timeout {
        case .seconds(let value):
            time = TimeInterval(value)
        default:
            break
        }
        
        // TODO: 这里还需要优化，设置每次发送数据时的tag，根据tag在delegate中进行写数据是否成功的判断，并异步回调给上层
        socket.write(data, withTimeout: time, tag: 0)
        socket.readData(withTimeout: -1, tag: 0)
        SLLog.debug("向\(socket.connectedHost ?? "nil host"):\(socket.connectedPort)发送数据:\n\(String(data: data, encoding: .utf8) ?? "some data which can't convert to string")\n")
    }
    
//    func setReceivedDataHandler(_ handler: SLSocketDataHandler?) {
//        dataHandler = handler
//    }
    
    @objc private func heartbeat() {
        if let socket = server, socket.isConnected, let heartbeatRule {
            try? send(heartbeatRule.requestValue)
            let timeout = Int(heartbeatRule.timeout)
            heartbeatTimeoutChecker?.cancel()
            heartbeatTimeoutChecker = nil
            heartbeatTimeoutChecker = SLCancelableWork(id: "\(currentClientDesc ?? "")心跳超时检测", delayTime: .seconds(Int(heartbeatRule.timeout))) { [weak self, weak sock = socket] in
                if let lastReadTime = self?.lastReadTime {
                    let currentTime = ProcessInfo.processInfo.systemUptime
                    let passedTime = Int(round(currentTime - lastReadTime))
                    if passedTime >= timeout {
                        SLLog.debug("\(self?.currentClientDesc ?? "")心跳已超时")
                        self?.state = .disconnectedUnexpected
                        self?.cachedData = nil
                        sock?.disconnect()
                        self?.acceptedClients.removeAll()
                        self?.currentClient = nil
                        self?.unexpectedDisconnectHandler?(.socketDisconnectedHeartbeatTimeout)
                        self?.state = .initilized
                    }
                }
            }
            heartbeatTimeoutChecker?.start(at: Self.queue)
        } else if let heartbeatTimer {
            heartbeatTimer.invalidate()
            self.heartbeatTimer = nil
        }
    }
    
    deinit {
        SLLog.debug("\(self) deinit")
    }
}

extension SLSocketServer: GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        let newSock = SLAcceptedSocket(host: newSocket.connectedHost, port: newSocket.connectedPort, socket: newSocket)
        switch gateway.connectionAuthrizationHandler(newSock, acceptedClients.count) {
        case .access(_):
            SLLog.debug("允许来自\(newSocket.connectedHost ?? "nil host"):\(newSocket.connectedPort)的连接")
            acceptedClients.append(newSock)
            newSocket.readData(withTimeout: -1, tag: 0)
        case .deny(let data):
            SLLog.debug("拒绝来自\(newSocket.connectedHost ?? "nil host"):\(newSocket.connectedPort)的连接")
            if let data {
                newSocket.write(data, withTimeout: -1, tag: 0)
                newSocket.disconnectAfterWriting()
            } else {
                newSocket.disconnect()
            }
        }
    }
    
    public func socketDidCloseReadStream(_ sock: GCDAsyncSocket) {
        SLLog.debug("\(sock.connectedHost ?? "nil host"):\(sock.connectedPort) didCloseReadStream")
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        var index = acceptedClients.firstIndex { item in
            item.socket.isEqual(sock)
        }
        while index != nil {
            let client = acceptedClients[index!]
            SLLog.debug("socket \(client.host ?? "nil host"):\(client.port)已断开连接\n\(err?.localizedDescription ?? "")\n")
            acceptedClients.remove(at: index!)
            index = acceptedClients.firstIndex { item in
                item.socket.isEqual(sock)
            }
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        // MARK: 目前只考虑双方基于JSON进行通信
        if let string = String(data: data, encoding: .utf8) {
            if let heartbeatRule, heartbeatRule.reponseValue.elementsEqual(string) {
                lastReadTime = ProcessInfo.processInfo.systemUptime
                // 心跳不交给上层处理
                return
            }
            print("\n来自\(sock.connectedHost ?? "nil host"):\(sock.connectedPort)的数据:\n\(string)\n")
            // 组包（？？？连续发送多个请求a，b，a的请求响应需要分多个包接收，接收过程中是否可能包含b的响应？考虑到tcp可以保证顺序性，应该不会出现这种情况，所以以下的组包应该是安全的）
            do {
                var totalData = cachedData ?? Data()
                totalData.append(data)
                cachedData = nil
                _ = try JSONSerialization.jsonObject(with: totalData)
                dataHandler?(totalData)
            } catch _ {
                cachedData == nil ? cachedData = Data() : nil
                cachedData!.append(data)
            }
        }
        sock.readData(withTimeout: -1, tag: 0)
    }
}
