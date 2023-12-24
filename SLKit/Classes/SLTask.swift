//
//  SLTask.swift
//  SLKit
//
//  Created by 蒋函锋 on 2023/12/14.
//

import Foundation

public enum SLTimeInterval {
    case infinity
    case seconds(Int)
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
