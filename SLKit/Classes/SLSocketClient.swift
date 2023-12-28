//
//  SLSocketClient.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/19.
//

import Foundation
import CocoaAsyncSocket
import RxSwift

public typealias SLSocketDataHandler = ((Data) -> Void)

public class SLSocketClient: SLSocket {
    
    fileprivate static let queue = DispatchQueue(label: "com.slkit.slsocket.client")
    
    fileprivate var connectionCompletion: ((SLResult<Void, SLError>) -> Void)?
    public var unexpectedDisconnectHandler: ((SLError?) -> Void)?
    fileprivate var socket: GCDAsyncSocket?
//    fileprivate var connectionTimeoutChecker: SLCancelableWork?
    
    private var dataHandler: SLSocketDataHandler?
    
    private var heartbeatTimer: Timer?
    private var lastReadTime: TimeInterval?
    private var heartbeatTimeoutChecker: SLCancelableWork?
    private var cachedData: Data?
    
    public var isConnected : Bool {
        return socket?.isConnected ?? false
    }
    
    override private init(host: String, port: UInt16, role: SLSocket.Role, heartbeatRule: SLSocketHeartbeatRule? = nil) {
        super.init(host: host, port: port, role: role, heartbeatRule: heartbeatRule)
    }
    
    public convenience init(host: String, port: UInt16, heartbeatRule: SLSocketHeartbeatRule? = nil) {
        self.init(host: host, port: port, role: .client, heartbeatRule: heartbeatRule)
    }
    
    public func getState() -> SLSocket.State {
        return state
    }
    
    public func startConnection(timeout: SLTimeInterval = .seconds(15), completion: @escaping ((_ result: SLResult<Void, SLError>) -> Void)) {
//        guard self.state != .connecting || self.state != .connected else {
//            completion(.failure(.socketConnectionErrorState))
//            return
//        }
        if self.state == .connected {
            completion(.success(Void()))
            return
        }
        self.connectionCompletion = completion
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: Self.queue)
        do {
            switch timeout {
            case .infinity:
                try self.socket?.connect(toHost: self.host, onPort: self.port)
            case .seconds(let value):
                try self.socket?.connect(toHost: self.host, onPort: self.port, withTimeout: TimeInterval(value))
//                self.connectionTimeoutChecker?.cancel()
//                self.connectionTimeoutChecker = nil
//                self.connectionTimeoutChecker = SLCancelableWork(delayTime: .seconds(value), closure: { [weak self] in
//                    if let state = self?.state, state == .connecting {
//                        completion(.failure(SLError.socketConnectionErrorState))
//                    }
//                })
//                self.connectionTimeoutChecker?.identifier = "socket连接检测\(Date().timeIntervalSince1970)"
//                self.connectionTimeoutChecker?.start(at: Self.queue)
            }
            self.state = .connecting
        } catch let error {
            completion(.failure(.socketConnectionFailure(error)))
        }
    }
    
    public func disconnect() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        heartbeatTimeoutChecker?.cancel()
        heartbeatTimeoutChecker = nil
        state = .initilized
        socket?.disconnect()
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
        guard let socket, socket.isConnected else {
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
    
    func setReceivedDataHandler(_ handler: SLSocketDataHandler?) {
        dataHandler = handler
    }
    
    @objc private func heartbeat() {
        if let socket, socket.isConnected, let heartbeatRule {
            try? send(heartbeatRule.sendValue)
            let timeout = Int(heartbeatRule.timeout)
            heartbeatTimeoutChecker?.cancel()
            heartbeatTimeoutChecker = nil
            heartbeatTimeoutChecker = SLCancelableWork(id: "socket(\(host):\(port))心跳超时检测", delayTime: .seconds(Int(heartbeatRule.timeout))) { [weak self, weak sock = socket] in
                if let lastReadTime = self?.lastReadTime {
                    let currentTime = ProcessInfo.processInfo.systemUptime
                    let passedTime = Int(round(currentTime - lastReadTime))
                    if passedTime >= timeout {
                        SLLog.debug("socket(\(sock?.connectedHost ?? "nil host"):\(sock?.connectedPort ?? 0))心跳已超时")
                        self?.state = .disconnectedUnexpected
                        sock?.disconnect()
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

extension SLSocketClient: GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        SLLog.debug("连接\(host):\(port)成功")
        sock.readData(withTimeout: -1, tag: 0)
        state = .connected
        connectionCompletion?(.success(Void()))
        if let heartbeatRule {
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                self.heartbeatTimer?.invalidate()
                self.heartbeatTimer = nil
                self.heartbeatTimer = Timer(timeInterval: TimeInterval(heartbeatRule.interval), target: self, selector: #selector(heartbeat), userInfo: nil, repeats: true)
                RunLoop.current.add(heartbeatTimer!, forMode: .commonModes)
                RunLoop.current.run()
            }
        }
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        cachedData = nil
        if state == .connecting {
            SLLog.debug("socket(\(host):\(port))连接失败")
            state = .initilized
            connectionCompletion?(.failure(.bleConnectionFailure(err)))
        } else if state == .connected {
            SLLog.debug("socket(\(host):\(port))断开连接")
            if let err {
                SLLog.debug("异常：\(err.localizedDescription)")
            }
            state = .disconnectedUnexpected
            unexpectedDisconnectHandler?(.socketDisconnected(err))
        }
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        heartbeatTimeoutChecker?.cancel()
        heartbeatTimeoutChecker = nil
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
                let json = try JSONSerialization.jsonObject(with: totalData)
                dataHandler?(totalData)
            } catch _ {
                cachedData == nil ? cachedData = Data() : nil
                cachedData!.append(data)
            }
        }
    }
}

extension Reactive where Base : SLSocketClient {
    public var connection: Observable<SLSocketClient> {
        return Observable<SLSocketClient>.create { observer in
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(15), execute: {
                observer.onNext(base)
//                observer.onCompleted()
            })
            return Disposables.create()
        }
    }
    
    public var listen: Observable<String> {
        return Observable<String>.create { observer in
            observer.onNext("hello world")
//            observer.onCompleted()
            return Disposables.create ()
        }
    }
}
