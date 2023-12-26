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
    fileprivate var disconnectedCallback: ((SLError?) -> Void)?
    fileprivate var socket: GCDAsyncSocket?
    fileprivate var connectionTimeoutChecker: SLCancelableWork?
    
    private var dataHandler: SLSocketDataHandler?
    var isConnected : Bool {
        return socket?.isConnected ?? false
    }
    
    override private init(host: String, port: UInt16, role: SLSocket.Role) {
        super.init(host: host, port: port, role: role)
    }
    
    public convenience init(host: String, port: UInt16) {
        self.init(host: host, port: port, role: .client)
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
                self.connectionTimeoutChecker?.cancel()
                self.connectionTimeoutChecker = SLCancelableWork(delayTime: .seconds(value), closure: { [weak self] in
                    if let state = self?.state, state == .connecting {
                        completion(.failure(SLError.socketConnectionErrorState))
                    }
                })
                self.connectionTimeoutChecker?.start(at: Self.queue)
            }
            self.state = .connecting
        } catch let error {
            completion(.failure(.socketConnectionFailure(error)))
        }
    }
    
    public func send(_ text: String, timeout: SLTimeInterval = .seconds(15)) throws {
        guard let socket, socket.isConnected else {
            throw SLError.socketSendFailureNotConnected
        }
        guard let data = text.data(using: .utf8), data.count > 0 else {
            throw SLError.socketSendFailureDataError
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
        socket.write(data, withTimeout: time, tag: 0)
        socket.readData(withTimeout: -1, tag: 0)
    }
    
    func setReceivedDataHandler(_ handler: SLSocketDataHandler?) {
        dataHandler = handler
    }
    
    deinit {
        SLLog.debug("\(self) deinit")
    }
}

extension SLSocketClient: GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        sock.readData(withTimeout: -1, tag: 0)
        state = .connected
        connectionTimeoutChecker?.cancel()
        connectionCompletion?(.success(Void()))
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if state == .connecting {
            connectionTimeoutChecker?.cancel()
            state = .disconnected
            connectionCompletion?(.failure(.bleConnectionFailure(err)))
        } else if state == .connected {
            state = .disconnected
            disconnectedCallback?(.socketDisconnected(err))
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if let string = String(data: data, encoding: .utf8) {
            print("\nreceived string from '\(sock.connectedHost != nil ? sock.connectedHost! + ":\(sock.connectedPort)" : "")':\n\(string)\n")
        }
        dataHandler?(data)
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
