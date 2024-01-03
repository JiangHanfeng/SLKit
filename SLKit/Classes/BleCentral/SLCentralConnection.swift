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
    
    typealias Result = SLResult<CBPeripheral, SLError>
    
    var id: String {
        return "\(unsafeBitCast(self, to: Int.self))"
    }
    
    public func start() throws {
        do {
            try SLCentralManager.shared.startConnection(self)
            switch timeout {
            case .infinity:
                break
            case .seconds(let int):
                checkStateWork = SLCancelableWork(delayTime: .seconds(int)) { [weak self] in
                    if let self {
                        switch self.state {
                        case .connecting:
                            self.terminate()
                        default:
                            break
                        }
                    }
                }
            }
        } catch let e {
            (e as? SLError).map { error in
                completion?(.failure(error))
            }
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
    
    func completed(result: SLResult<CBPeripheral, SLError>) {
        completion?(result)
    }
    
    public func terminate() {
        SLCentralManager.shared.stopConnection(self)
    }
    
    public static func == (lhs: SLCentralConnection, rhs: SLCentralConnection) -> Bool {
        lhs.peripheral.isEqual(rhs.peripheral)
    }
    
    let peripheral: CBPeripheral
    let timeout: SLTimeInterval
    private var checkStateWork: SLCancelableWork?
    let completion: ((_ result: SLResult<CBPeripheral, SLError>) -> Void)?
    let disconnectedCallback: ((_ error: SLError?) -> Void)?
    private var iState = SLCentralConnectionState.initial
    
    public var state: SLCentralConnectionState {
        get {
            return iState
        }
    }
    
    public init(
        peripheral: CBPeripheral,
        timeout: SLTimeInterval = .seconds(15),
        completion: @escaping ((_ result: SLResult<CBPeripheral, SLError>) -> Void),
        disconnectedCallback: @escaping ((_ error: SLError?) -> Void)
    ) {
        self.peripheral = peripheral
        self.timeout = timeout
        self.completion = completion
        self.disconnectedCallback = disconnectedCallback
    }
}
