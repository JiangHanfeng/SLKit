//
//  SCLHomeViewModel.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import CoreBluetooth

class SCLHomeViewModel {
    let ipValid: Observable<Bool>
    let bleValid: Observable<Bool>
    let allValid: Observable<Bool>
    
    init(ip: Observable<String>, bleState: Observable<CBManagerState>) {
        self.ipValid = ip.map({!$0.isEmpty}).share(replay: 1)
        self.bleValid = bleState.map({$0 == .poweredOn}).share(replay: 1)
        self.allValid = Observable.combineLatest(ipValid, bleValid) { $0 && $1}.share(replay: 1)
    }
}
