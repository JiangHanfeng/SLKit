//public typealias SLCancelableWorkItem = (_ cancel: Bool) -> Void
//
//public func delay(_ time: DispatchTimeInterval, execute: @escaping (() -> Void)) -> SLCancelableWorkItem? {
//    func dispatch_later(_ work: @escaping (() -> Void)) {
//        let desTime = DispatchTime.now() + time
//        DispatchQueue.main.asyncAfter(deadline: desTime, execute: work)
//    }
//    
//    var closure: (() -> Void)? = execute
//    var result: SLCancelableWorkItem?
//    
//    let delayClosure: SLCancelableWorkItem = { cancel in
//        if let internalClosure = closure {
//            if !cancel {
//                DispatchQueue.main.async(execute: internalClosure)
//            }
//        }
//        closure = nil
//        result = nil
//    }
//    
//    result = delayClosure
//    
//    dispatch_later {
//        if let delayedClosure = result {
//            delayedClosure(false)
//        } else {
//            print("result has been reset to nil")
//        }
//    }
//    
//    return result
//}

public enum SLError: Error, LocalizedError {
    case internalStateError(String)
    case bleNotPowerOn
    case bleScanTimeout
    case bleConnectionTimeout
    case bleConnectionFailure(Error?)
    case bleDisconnected(Error?)
    case locationNotAllowed
    case socketWrongRole
    case socketWrongClientState
    case socketConnectionFailure(Error?)
    case socketConnectionTimeout
    case socketDisconnectedHeartbeatTimeout
    case socketDisconnected(Error?)
    case socketSendFailureNotConnected
    case socketSendFailureEmptyData
    case socketSendFailureDataError
    case socketNotConnectedYet
    case socketDisconnectedWaitingForResponse
    case socketHasBeenReleased
    case socketWrongServerState
    case socketListenFailure(Error)
    case taskCanceled
    case taskTimeout
    
    public var errorDescription: String? {
        switch self {
        case .internalStateError(let msg):
            return msg
        case .bleNotPowerOn:
            return "the CBManagerState not powerOn at this moment"
        case .bleScanTimeout:
            return "scan ble peripheral out of time"
        case .bleConnectionTimeout:
            return "connect ble peripheral out of time"
        case .bleConnectionFailure(let error):
            return error != nil ? error!.localizedDescription : "ble connection failure"
        case .bleDisconnected(let error):
            return error != nil ? error!.localizedDescription : "ble disconnected"
        case .locationNotAllowed:
            return "未授予定位权限"
        case .socketWrongClientState:
            return "socket wrong state"
        case .socketConnectionFailure(let error):
            return error?.localizedDescription ?? "socket connect failed"
        case .socketConnectionTimeout:
            return "socket connect timeout"
        case .socketDisconnectedHeartbeatTimeout:
            return "socket disconnected because of heartbeat timeout"
        case .socketDisconnected(let error):
            return error != nil ? error!.localizedDescription : "socket disconnected"
        case .socketSendFailureNotConnected:
            return "send data failed because the socket hasn't been connected yet"
        case .socketSendFailureEmptyData:
            return "send data failed because the data can't be empty or nil"
        case .socketSendFailureDataError:
            return "send data failed because the string can't convert to Data"
        case .socketNotConnectedYet:
            return "socket hasn't been connected yet"
        case .socketDisconnectedWaitingForResponse:
            return "socket has disconected when waiting for the response"
        case .socketHasBeenReleased:
            return "socket has been released"
        case .socketWrongServerState:
            return "socket serve error state"
        case .socketWrongRole:
            return "socket wrong role"
        case .socketListenFailure(let error):
            return error.localizedDescription
        case .taskCanceled:
            return "任务已取消"
        case .taskTimeout:
            return "任务超时"
        }
    }
}

public enum SLResult<T, E: Error> {
    case success(_ value : T)
    case failure(_ error: E)
}

public enum SLTimeInterval {
    case infinity
    case seconds(TimeInterval)
}

protocol SLTask: Equatable {
    associatedtype Exception
    associatedtype Progress
    associatedtype Result
    
    var id: String { get }
    
    func start() throws
    
    func exception(e: Exception)
    
    func update(progress: Progress)
    
    func completed(result: Result)
    
    func terminate() throws
}


public class SLCancelableWork {
    var delayTime: DispatchTimeInterval
    var closure: (() -> Void)?
    var shouldCancel = false
    var identifier: String?
    
    public init(id: String? = nil, delayTime: DispatchTimeInterval = .never, closure: @escaping () -> Void) {
        self.identifier = id
        self.delayTime = delayTime
        self.closure = closure
    }
    
    public func start(at queue: DispatchQueue) {
        shouldCancel = false
        if delayTime == .never {
            startImmediately(at: queue)
        } else {
            queue.asyncAfter(deadline: .now() + delayTime, execute: DispatchWorkItem(block: { [weak self] in
                if let cancel = self?.shouldCancel, !cancel, let closure = self?.closure {
                    SLLog.debug("SLCancelableWork:\(self?.identifier ?? "")执行")
                    closure()
                } else if let self {
//                    SLLog.debug("SLCancelableWork:\(self.identifier ?? "")无法执行-已取消")
                }
            }))
        }
    }
    
    public func startImmediately(at queue: DispatchQueue) {
        queue.async { [weak self] in
            if let cancel = self?.shouldCancel, !cancel {
                self?.closure?()
            } else if let identifier = self?.identifier {
//                SLLog.debug("SLCancelableWork(\(identifier))无法执行:已取消")
            }
        }
    }
    
    public func cancel() {
//        SLLog.debug("SLCancelableWork:\(identifier ?? "")取消")
        self.shouldCancel = true
        self.closure = nil
    }
    
    deinit {
        print("\(self):\(identifier ?? "") deinit")
    }
}

extension UInt8 {
    var hexString : String {
        get {
            return String(format: "%02X", self)
        }
    }
}

public func randomMacAddressString() -> String {
    return [
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255)
    ].map { uint8 in
        return uint8.hexString
    }.joined(separator: ":")
}

public func stackAddress(of: UnsafeRawPointer) -> Int {
    return Int(bitPattern: of)
}

public func headAddress<T: AnyObject>(of: T) -> Int {
    return unsafeBitCast(of, to: Int.self)
}

extension Date {
    static func now(dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formattor = DateFormatter()
        formattor.dateFormat = dateFormat
        return formattor.string(from: Date())
    }
}


import CoreLocation
import CoreBluetooth

public final class SLConnectivityManager {
    public static let shared = {
        let singleInstance = SLConnectivityManager()
        return singleInstance
    }()
    
    private var bleStateUpdatedHandlers: [SLBleStateUpdatedHandler] = []
    var a2dpDevice: SLA2DPDevice? {
        get {
            return SLA2DPMonitor.shared.connectedDevice()
        }
    }
    
    private var peripheralManager = SLPeripheralManager(queue: DispatchQueue(label: "com.slkit.peripheral"))
    
    private init() {}
    
    public func connectWifi(ssid: String, passphrase: String, completionHandler: @escaping ((_ error: Error?) -> Void)) {
        SLNetworkManager.shared.connectWifi(ssid: ssid, passphrase: passphrase, completionHandler: completionHandler)
    }
           
    public func getConnectedWifi(completionHandler: @escaping ((_ ssid: String?, _ bssid: String?, _ error: Error?) -> Void)) {
        SLNetworkManager.shared.getConnectedWifi(completionHandler: completionHandler)
    }
    
    public func startScan<U: SLDeviceBuilder>(
        deviceBuilder: U.Type,
        timeout: SLTimeInterval = .infinity,
        filter: ((U.Device) -> Bool)? = nil,
        discovered: @escaping ((_ devices: [U.Device]) -> Bool),
        errored: @escaping ((SLError) -> Void),
        finished: @escaping (() -> Void)
    ) {
        SLDeviceScanTask(anyDevice: SLAnyDevice(base: deviceBuilder))
            .start(timeout: timeout, filter: filter, discovered: discovered, errored: errored, finished: finished)
    }
    
    public func stopScan() {
        SLCentralManager.shared.stopScan()
    }
    
    public func connectDevice<T: SLBaseDevice>(_ device: T) {
        switch device.type {
        case .freestyle(key: _):
            let connection = SLCentralConnection(peripheral: device.peripheral) { result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    break
                }
            } disconnectedCallback: { error in
                
            }
        default:
            break
        }
    }
    
    public func disconnectDevice() {
        SLCentralManager.shared.disconnectAll()
    }
    
    public func bleAvailable() -> Bool {
        return SLCentralManager.shared.available() && peripheralManager.available()
    }
}
