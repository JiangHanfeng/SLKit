public typealias SLCancelableWorkItem = (_ cancel: Bool) -> Void

public func delay(_ time: DispatchTimeInterval, execute: @escaping (() -> Void)) -> SLCancelableWorkItem? {
    func dispatch_later(_ work: @escaping (() -> Void)) {
        let desTime = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: desTime, execute: work)
    }
    
    var closure: (() -> Void)? = execute
    var result: SLCancelableWorkItem?
    
    let delayClosure: SLCancelableWorkItem = { cancel in
        if let internalClosure = closure {
            if !cancel {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        } else {
            print("result has been reset to nil")
        }
    }
    
    return result
}

public class SLCancelableWork {
    var delayTime: DispatchTimeInterval
    var closure: (() -> Void)
    var shouldCancel = false
    public var identifier: String?
    
    public init(delayTime: DispatchTimeInterval = .never, closure: @escaping () -> Void) {
        self.delayTime = delayTime
        self.closure = closure
    }
    
    public func start(at queue: DispatchQueue) {
        if delayTime == .never {
            startImmediately(at: queue)
        } else {
            queue.asyncAfter(deadline: .now() + delayTime, execute: DispatchWorkItem(block: { [weak self] in
                if let cancel = self?.shouldCancel, !cancel {
                    SLLog.debug("SLCancelableWork(\(self?.identifier ?? ""))执行")
                    self?.closure()
                } else if let identifier = self?.identifier {
                    SLLog.debug("SLCancelableWork(\(identifier))无法执行:已取消")
                }
            }))
        }
    }
    
    public func startImmediately(at queue: DispatchQueue) {
        queue.async { [weak self] in
            if let cancel = self?.shouldCancel, !cancel {
                self?.closure()
            } else if let identifier = self?.identifier {
                SLLog.debug("SLCancelableWork(\(identifier))无法执行:已取消")
            }
        }
    }
    
    public func cancel() {
        self.shouldCancel = true
        if let identifier {
            SLLog.debug("SLCancelableWork(\(identifier))已取消")
        }
    }
}
