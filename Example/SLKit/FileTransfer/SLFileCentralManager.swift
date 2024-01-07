//
//  SLFileCentralManager.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/7.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation



enum SLFileTranferType {
    case receive
    case send
}

enum SLFileTransferError : String, Error {
    case refused = "对方已拒绝"
    case failed = "传输失败"
}

enum SLFileTransferResult {
    case success
    case failure(_ error: SLFileTransferError)
}

enum SLFileTransferItemStatus {
    case waitingConfirmed
    case transferring(_ progress: Int)
    case completed(_ result: SLFileTransferResult)
}

class SLFileTransferItem {
    let fileName: String
    var status: SLFileTransferItemStatus
    let taskId: String
    
    init(fileName: String, status: SLFileTransferItemStatus, taskId: String) {
        self.fileName = fileName
        self.status = status
        self.taskId = taskId
    }
}

/// 文件传输集合
class SLFileTransferSequence : Equatable {
    static func == (lhs: SLFileTransferSequence, rhs: SLFileTransferSequence) -> Bool {
        if lhs.id.elementsEqual(rhs.id) {
            if lhs.type == rhs.type {
                if lhs.items.count == rhs.items.count {
                    var isSame = true
                    for l in lhs.items {
                        for r in rhs.items {
                            if
                                !l.taskId.elementsEqual(r.taskId)
                                    ||
                                !l.fileName.elementsEqual(r.fileName) {
                                isSame = false
                                break
                            }
                            if !isSame {
                                break
                            }
                        }
                    }
                    return isSame
                }
                return false
            }
            return false
        }
        return false
    }
    
    let id: String!
    let type: SLFileTranferType
    let items: [SLFileTransferItem]
    
    init(type: SLFileTranferType, items: [SLFileTransferItem]) {
        guard !items.isEmpty else {
            fatalError("the items in transfer sequence should not be empty")
        }
        self.type = type
        self.items = items
        self.id = "T\(Int(Date().timeIntervalSince1970 * 1000))" + "P\(Int(ProcessInfo.processInfo.systemUptime * 1000))"
    }
}

class SLFileCentralManager {
    public static let shared = SLFileCentralManager()
    private static let queue = DispatchQueue(label: "com.slkit.fileCentral")
    private var transferringSeqs = Array<SLFileTransferSequence>()
    private init() {}
    
    func addTransferringSequence(_ seqs: SLFileTransferSequence) {
        if let _ = transferringSeqs.firstIndex(where: {
            $0 == seqs
        }) {
            
        } else {
            transferringSeqs.append(seqs)
        }
    }
    
    @available(*, renamed: "addTransferringSequence(_:)")
    func addTransferringSequence(_ seqs: SLFileTransferSequence, completion: @escaping (() -> Void)) {
        Task {
            await addTransferringSequence(seqs)
            completion()
        }
    }
    
    func addTransferringSequence(_ seqs: SLFileTransferSequence) async {
        return await withCheckedContinuation { continuation in
            Self.queue.async {
                self.addTransferringSequence(seqs)
                continuation.resume(returning: ())
            }
        }
    }
}
