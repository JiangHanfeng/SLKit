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
    
    private var connectionTimeoutChecker: SLCancelableWork?
    
    var dataHandler: SLSocketDataCallback?
    
    private var lastHeartbeatTime: TimeInterval?

    private var lastReadTime: TimeInterval?
    
    private var heartbeatTimeoutChecker: SLCancelableWork?
    
    /// 存储socket read收到的二进制流
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
                self.connectionTimeoutChecker?.cancel()
                self.connectionTimeoutChecker = nil
                switch timeout {
                case .infinity:
                    break
                case .seconds(let seconds):
                    self.connectionTimeoutChecker = SLCancelableWork(id: "\(Date.now())开启的连接超时检测任务", delayTime: .seconds(Int(seconds)), closure: { [weak self] in
                        guard let self else { return }
                        if self.state != .connected {
                            SLLog.debug("检测到连接超时")
                            self.disconnectInternal(with: nil)
                            completion(.failure(.socketConnectionTimeout))
                        }
                    })
                    self.connectionTimeoutChecker?.start(at: Self.queue)
                }
            } catch let error {
                self.state = .initilized
                self.server = nil
                completion(.failure(.socketConnectionFailure(error)))
            }
        }
    }
    
    public func disconnect() {
        disconnectInternal(with: nil)
    }
    
    private func disconnectInternal(with error: Error?) {
        stopHeartbeatTimeoutChecker()
        error == nil ? state = .initilized : nil
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
            SLLog.debug("发送:\n\(string)")
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
    
    @objc private func responseHeartbeat() {
        guard let socket = server, socket.isConnected else {
            SLLog.debug("回复心跳时异常：socket已被释放")
            return
        }
        guard socket.isConnected else {
            SLLog.debug("回复心跳时异常：socket未连接")
            return
        }
        var bytes: [UInt8] = []
        let type = UInt8(0x00)
        bytes.append(type)
        let length = UInt32(0)
        withUnsafeBytes(of: length.bigEndian) {
            bytes.append(contentsOf: $0)
        }
        do {
            try send(Data(bytes: bytes))
        } catch let e {
            SLLog.debug("回复心跳时异常：\(e.localizedDescription)")
        }
    }
    
    private func stopHeartbeatTimeoutChecker() {
        heartbeatTimeoutChecker?.cancel()
        heartbeatTimeoutChecker = nil
    }
    
    private func startCheckHeartbeatTimeout() {
        let seconds = Int(heartbeatRule?.timeout ?? 10)
        let timeout = TimeInterval(seconds)
        heartbeatTimeoutChecker = SLCancelableWork(id: "\(Date.now())开启的心跳超时检测任务", delayTime: .seconds(seconds), closure: { [weak self] in
            guard let self, self.state == .connected else {
                return
            }
            let currentTime = ProcessInfo.processInfo.systemUptime
            let passedTime = currentTime - (self.lastReadTime ?? 0)
            if passedTime >= timeout {
                SLLog.debug("检测到心跳超时")
                self.disconnectInternal(with: SLError.socketDisconnectedHeartbeatTimeout)
            }
        })
        heartbeatTimeoutChecker?.start(at: Self.queue)
    }
    
    private func restartCheckHeartbeatTimeout() {
        stopHeartbeatTimeoutChecker()
        startCheckHeartbeatTimeout()
    }
    
    deinit {
        SLLog.debug("\(self) deinit")
    }
}

extension SLSocketClient: GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        SLLog.debug("本机\(sock.localHost ?? ""):\(sock.localPort)已连接服务器\(self.host):\(self.port)")
        connectionTimeoutChecker?.cancel()
        connectionTimeoutChecker = nil
        cachedData?.removeAll()
        state = .connected
        connectionCompletion?(.success(Void()))
        restartCheckHeartbeatTimeout()
        server?.readData(withTimeout: -1, tag: 0)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        stopHeartbeatTimeoutChecker()
        server = nil
        cachedData?.removeAll()
        if state == .connecting {
            SLLog.debug("\(serverDesc ?? "socket")连接失败")
            connectionTimeoutChecker?.cancel()
            connectionTimeoutChecker = nil
            state = .initilized
            connectionCompletion?(.failure(.socketConnectionFailure(err)))
        } else if state == .connected {
            SLLog.debug("与\(host):\(port)的连接已断开")
            if let err {
                SLLog.debug("断连异常:\(err.localizedDescription)")
            }
            state = .disconnectedUnexpected
            DispatchQueue.main.async { [weak self] in
                self?.unexpectedDisconnectHandler?(.socketDisconnected(err))
            }
            state = .initilized
        } else {
            SLLog.debug("socket正常断开")
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        Self.queue.async {
            self.didReceived(data: data, from: sock)
        }
    }
    
    private func didReceived(data: Data, from: GCDAsyncSocket) {
        restartCheckHeartbeatTimeout()
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
        SLLog.debug("deal data type:\(type), value length = \(length), current received bytes length = \(bytes.count)")
        if length > 0 && type != SLSocketSessionItemType.heartbeat.rawValue {
            SLLog.debug("will intercept value bytes for range 5...\(bytes.index(before: 5+Int(length))) and left bytes for range \(bytes.index(after: 4+Int(length)))..<\(bytes.endIndex)")
            let leftBytes = bytes[bytes.index(after: 4+Int(length))..<bytes.endIndex]
            cachedData = Data(bytes: leftBytes)
            let valueBytes = bytes[5...bytes.index(before: 5+Int(length))]
            let valueData = Data(bytes: valueBytes)
            let gbkEncoding = CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
            if let valueString = String(data: valueData, encoding: .utf8) {
                SLLog.debug("来自\(host):\(port)的业务消息/系统消息(\(length)bytes):\n\(valueString)")
                dataHandler?(valueData)
            } else if let valueString = String(data: valueData, encoding: String.Encoding(rawValue: gbkEncoding)) {
                SLLog.debug("来自\(host):\(port)的业务消息/系统消息(\(length)bytes，需进行gbk转utf8):\n\(valueString)")
                if let newValueData = valueString.data(using: .utf8) {
                    dataHandler?(newValueData)
                } else {
                    dataHandler?(valueData)
                }
            } else {
                SLLog.debug("来自\(host):\(port)的业务消息/系统消息(\(length)bytes)无法解析")
                dataHandler?(valueData)
            }
        } else {
            cachedData?.removeAll()
            if type == SLSocketSessionItemType.heartbeat.rawValue {
                SLLog.debug("来自\(from.connectedHost ?? ""):\(from.connectedPort)的心跳包(\(length)bytes)")
                responseHeartbeat()
            } else {
                SLLog.debug("来自\(from.connectedHost ?? ""):\(from.connectedPort)的无效数据")
            }
        }
    }
}
