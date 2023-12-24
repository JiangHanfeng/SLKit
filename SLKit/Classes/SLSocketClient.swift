//
//  SLSocketClient.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/19.
//

import Foundation
import CocoaAsyncSocket
import RxSwift

public class SLSocketClient: SLSocket {
    
    fileprivate static let queue = DispatchQueue(label: "com.slkit.slsocket.client")
    
    fileprivate var connectionCompletion: ((SLResult<Void, SLError>) -> Void)?
    fileprivate var disconnectedCallback: ((SLError?) -> Void)?
    fileprivate var socket: GCDAsyncSocket?
    
    override private init(host: String, port: UInt16, role: SLSocket.Role) {
        super.init(host: host, port: port, role: role)
    }
    
    public convenience init(host: String, port: UInt16) {
        self.init(host: host, port: port, role: .client)
    }
    
    public func startConnection(timeout: SLTimeInterval = .seconds(15), completion: @escaping ((_ result: SLResult<Void, SLError>) -> Void)) {
        guard self.state != .connecting || self.state != .connected else {
            completion(.failure(.socketConnectionErrorState))
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
            }
            self.state = .connecting
        } catch let error {
            completion(.failure(.socketConnectionFailure(error)))
        }
    }
    
    deinit {
        SLLog.debug("\(self) deinit")
    }
}

extension SLSocketClient: GCDAsyncSocketDelegate {
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        connectionCompletion?(.success(Void()))
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        disconnectedCallback?(.socketDisconnected(err))
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
