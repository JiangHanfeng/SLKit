//
//  SLCentralConnection.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/12.
//

import Foundation
import CoreBluetooth

public enum SLCentralConnectionState {
    case initial
    case connecting
    case connected
    case disconnectedWithError
}

public class SLCentralConnection : SLTask {

    typealias Exception = SLError
    
    typealias Progress = SLCentralConnectionState
    
    typealias Result = SLResult<Void, Error>
    
    private lazy var address: Int = {
        return unsafeBitCast(self, to: Int.self)
    }()
    
    var id: Int {
        return address
    }
    
    public func start() throws {
        do {
            let completionHandler = completion
            checkStateWork = SLCancelableWork(delayTime: .milliseconds(Int(timeout * 1000))) { [weak self] in
                let connected = self?.state == .connected
                if !connected {
                    self?.terminate()
                }
                completionHandler?(connected ? .success(Void()) : .failure(SLError.bleConnectionTimeout))
            }
            checkStateWork?.start(at: DispatchQueue.global())
            try SLCentralManager.shared.startConnection(self)
        } catch let e {
            checkStateWork?.cancel()
            checkStateWork = nil
            completion?(.failure(e))
        }
    }
    
    func exception(e: SLError) {
        switch e {
        case .bleDisconnected(let error):
            disconnectedCallback?(.bleDisconnected(error))
        default:
            break
        }
    }
    
    func update(progress: SLCentralConnectionState) {
        iState = progress
    }
    
    func completed(result: SLResult<Void, Error>) {
        completion?(result)
    }
    
    public func terminate() {
        SLCentralManager.shared.stopConnection(self)
    }
    
    public static func == (lhs: SLCentralConnection, rhs: SLCentralConnection) -> Bool {
        lhs.peripheral.isEqual(rhs.peripheral)
    }
    
    let peripheral: CBPeripheral
    let timeout: TimeInterval
    private var checkStateWork: SLCancelableWork?
    var completion: ((_ result: SLResult<Void, Error>) -> Void)?
    var disconnectedCallback: ((_ error: SLError?) -> Void)?
    private var iState = SLCentralConnectionState.initial
    
    public var state: SLCentralConnectionState {
        get {
            return iState
        }
    }
    
    public init(
        peripheral: CBPeripheral,
        timeout: TimeInterval = 5
    ) {
        self.peripheral = peripheral
        self.timeout = timeout
    }
    
    @available(*, renamed: "start(with:)")
    public func start(with completion: @escaping ((_ result: SLResult<Void, Error>) -> Void)
    ) {
        Task {
            do {
                try await start()
                completion(.success(Void()))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
    
    
    public func start() async throws {
            return try await withCheckedThrowingContinuation { continuation in
                do {
                    self.completion = { [weak self]
                        result in
                        self?.completion = nil
                        switch result {
                        case .success(_):
                            continuation.resume()
                        case .failure(let e):
                            continuation.resume(throwing: e)
                        }
                    }
                    try self.start()
                } catch let error {
                    completion = nil
                    continuation.resume(throwing: error)
                }
            }
    }
}
