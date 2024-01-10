//
//  SLSocketClient.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/19.
//

import Foundation
import CocoaAsyncSocket

public class SLSocketClient : NSObject {

    public enum State {
        case initilized
        case connecting
        case connected
        case disconnectedUnexpected
    }
    
    fileprivate static let queue = DispatchQueue(label: (Bundle.main.bundleIdentifier ?? "com") + ".slkit.socket.client")
    
    public let host : String
    
    public let port: UInt16
    
    public var localHost: String? {
        return server?.localHost
    }
    
    private var state: State!
    
    public let heartbeatRule: SLSocketHeartbeatRule?
    
    fileprivate var connectionCompletion: ((SLResult<Void, SLError>) -> Void)?
    
    public var unexpectedDisconnectHandler: ((SLError?) -> Void)?
    
    fileprivate var server: GCDAsyncSocket?
    
    fileprivate var serverDesc : String? {
        get {
            return server != nil ? "\(server!.connectedHost ?? "nil host"):\(server!.connectedPort)" : nil
        }
    }
    
    var dataHandler: SLSocketDataCallback?
    
    private var heartbeatTimer: Timer?
    
    private var lastHeartbeatTime: TimeInterval?

    private var lastReadTime: TimeInterval?
    
    private var heartbeatTimeoutChecker: SLCancelableWork?
    
    private var cachedData: Data?
    
    public var isConnected : Bool {
        return server?.isConnected ?? false
    }
    
    public func getState() -> SLSocketClient.State {
        return state
    }
    
    public init(host: String, port: UInt16, heartbeatRule: SLSocketHeartbeatRule? = nil) {
        self.host = host
        self.port = port
        self.heartbeatRule = heartbeatRule
        self.state = .initilized
    }
    
    public func startConnection(timeout: SLTimeInterval = .seconds(15), completion: @escaping ((_ result: SLResult<Void, SLError>) -> Void)) {
        Self.queue.async {
            if self.state == .connected {
                completion(.success(Void()))
                return
            }
            guard (self.state == .initilized || self.state == .disconnectedUnexpected) else {
                completion(.failure(SLError.socketWrongClientState))
                return
            }
            self.connectionCompletion = completion
            self.server = GCDAsyncSocket(delegate: self, delegateQueue: Self.queue)
            do {
                self.state = .connecting
                try self.server?.connect(toHost: self.host, onPort: self.port)
//                switch timeout {
//                case .infinity:
//                    try self.server?.connect(toHost: self.host, onPort: self.port)
//                case .seconds(let value):
//                    try self.server?.connect(toHost: self.host, onPort: self.port, withTimeout: TimeInterval(value))
//                }
            } catch let error {
                self.state = .initilized
                self.server = nil
                completion(.failure(.socketConnectionFailure(error)))
            }
        }
    }
    
    public func disconnect() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        heartbeatTimeoutChecker?.cancel()
        heartbeatTimeoutChecker = nil
        state = .initilized
        server?.disconnect()
        server = nil
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
    
    public func send(_ value: Data, type: UInt8, timeout: SLTimeInterval = .seconds(15)) throws {
        if type != SLSocketSessionItemType.heartbeat.rawValue, let string = String(data: value, encoding: .utf8) {
            SLLog.debug("socket发送:\n\(string)\n")
        }
        var data = Data()
        data.append(Data(bytes: [type]))
        var lengthBytes: [UInt8] = []
        let length = UInt32(value.count)
        withUnsafeBytes(of: length.bigEndian) {
            lengthBytes.append(contentsOf: $0)
        }
        data.append(Data(bytes: lengthBytes))
        data.append(value)
        try send(data, timeout: timeout)
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
        
        socket.write(data, withTimeout: time, tag: 0)
    }
    
    @objc private func sendHeartbeat() {
        if let socket = server, socket.isConnected, let heartbeatRule {
            var bytes: [UInt8] = []
            let type = UInt8(0x00)
            bytes.append(type)
            let length = UInt32(0)
            withUnsafeBytes(of: length.bigEndian) {
                bytes.append(contentsOf: $0)
            }
            try? send(Data(bytes: bytes))
            let currentTime = ProcessInfo.processInfo.systemUptime
            if let lastReadTime, Int(round(currentTime - lastReadTime)) < heartbeatRule.interval {
                // 当上次接收数据和本次心跳之间间隔不超过一个心跳周期，比如心跳周期为3秒，第0秒发送了一次心跳，第2秒收到一次业务数据响应，那么本该在第三秒发送的心跳就没必要发了
                return
            }
            guard lastHeartbeatTime == nil else {
                return
            }
            lastHeartbeatTime = currentTime
            let timeout = Int(heartbeatRule.timeout)
            heartbeatTimeoutChecker?.cancel()
            heartbeatTimeoutChecker = nil
            heartbeatTimeoutChecker = SLCancelableWork(id: "\(serverDesc ?? "")心跳超时检测", delayTime: .seconds(Int(heartbeatRule.timeout + 900))) { [weak self] in
                if let lastHeartbeatTime = self?.lastHeartbeatTime {
                    let currentTime = ProcessInfo.processInfo.systemUptime
                    let passedTime = Int(round(currentTime - lastHeartbeatTime))
                    if passedTime >= timeout {
                        self?.handleHeartbeatTimeout()
                    }
                }
            }
            heartbeatTimeoutChecker?.start(at: Self.queue)
        } else if let heartbeatTimer {
            heartbeatTimer.invalidate()
            self.heartbeatTimer = nil
        }
    }
    
    private func handleHeartbeatTimeout() {
        SLLog.debug("\(serverDesc ?? "")心跳已超时")
        state = .disconnectedUnexpected
        server?.disconnect()
        unexpectedDisconnectHandler?(.socketDisconnectedHeartbeatTimeout)
        state = .initilized
    }
    
    deinit {
        SLLog.debug("\(self) deinit")
    }
}

extension SLSocketClient: GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        SLLog.debug("本机\(sock.localHost ?? ""):\(sock.localPort)已连接服务器\(self.host):\(self.port)")
        cachedData?.removeAll()
        state = .connected
        connectionCompletion?(.success(Void()))
        server?.readData(withTimeout: -1, tag: 0)
//        if heartbeatRule != nil {
//            DispatchQueue.global().async { [weak self] in
//                guard let self else { return }
//                self.heartbeatTimer?.invalidate()
//                self.heartbeatTimer = nil
//                self.heartbeatTimer = Timer(timeInterval: TimeInterval(1), target: self, selector: #selector(Self.sendHeartbeat), userInfo: nil, repeats: true)
//                RunLoop.current.add(self.heartbeatTimer!, forMode: .commonModes)
//                RunLoop.current.run()
//            }
//        }
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        server = nil
        cachedData?.removeAll()
        if state == .connecting {
            SLLog.debug("\(serverDesc ?? "socket")连接失败")
            state = .initilized
            connectionCompletion?(.failure(.bleConnectionFailure(err)))
        } else if state == .connected {
            SLLog.debug("\(serverDesc ?? "socket")断开连接")
            if let err {
                SLLog.debug("异常：\(err.localizedDescription)")
            }
            state = .disconnectedUnexpected
            unexpectedDisconnectHandler?(.socketDisconnected(err))
        } else {
            SLLog.debug("\(serverDesc ?? "socket")正常断开")
        }
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        heartbeatTimeoutChecker?.cancel()
        heartbeatTimeoutChecker = nil
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        Self.queue.async {
            self.didReceived(data: data, from: sock)
        }
    }
    
    private func didReceived(data: Data, from: GCDAsyncSocket) {
        server?.readData(withTimeout: -1, tag: 0)
        lastReadTime = ProcessInfo.processInfo.systemUptime
        if cachedData == nil {
            cachedData = Data()
        }
        cachedData!.append(data)
        guard cachedData!.count > 0 else {
            return
        }
        let bytes = cachedData!.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: data.count))
        }
        guard bytes.count > 4 else {
            return
        }
        let type = bytes.first!
        let length = UInt32(bigEndian: Data(bytes: bytes[1...4]).withUnsafeBytes({ $0.pointee }))
        if length > 0 && type != SLSocketSessionItemType.heartbeat.rawValue {
            let leftBytes = bytes[bytes.index(after: 4+Int(length))..<bytes.endIndex]
            cachedData = Data(bytes: leftBytes)
            let valueBytes = bytes[5...bytes.index(before: 5+Int(length))]
            let valueData = Data(bytes: valueBytes)
            #if DEBUG
            if let valueString = String(data: valueData, encoding: .utf8) {
                SLLog.debug("来自\(from.connectedHost ?? ""):\(from.connectedPort)的业务消息/系统消息(\(length)bytes):\n\(valueString)")
            } else {
                SLLog.debug("来自\(from.connectedHost ?? ""):\(from.connectedPort)的业务消息/系统消息(\(length)bytes)无法解析")
            }
            #else
            #endif
            dataHandler?(valueData)
        } else {
            cachedData?.removeAll()
            #if DEBUG
            if type == SLSocketSessionItemType.heartbeat.rawValue {
                SLLog.debug("来自\(from.connectedHost ?? ""):\(from.connectedPort)的心跳包(\(length)bytes)")
                sendHeartbeat()
            } else {
                SLLog.debug("来自\(from.connectedHost ?? ""):\(from.connectedPort)的无效数据")
            }
            #else
            #endif
        }
    }
}

//import RxSwift
//extension Reactive where Base : SLSocketClient {
//    public var connection: Observable<SLSocketClient> {
//        return Observable<SLSocketClient>.create { observer in
//            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(15), execute: {
//                observer.onNext(base)
////                observer.onCompleted()
//            })
//            return Disposables.create()
//        }
//    }
//    
//    public var listen: Observable<String> {
//        return Observable<String>.create { observer in
//            observer.onNext("hello world")
////            observer.onCompleted()
//            return Disposables.create ()
//        }
//    }
//}
