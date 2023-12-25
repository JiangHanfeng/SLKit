//
//  SCLBaseViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/19.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SLKit
import SnapKit

class SCLBaseViewController: UIViewController {

    public let disposeBag = DisposeBag()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init() {
        let bundle = Bundle.main
        let nibName = String(describing: Self.self)
        if let _ = bundle.path(forResource: nibName, ofType: "nib") {
            self.init(nibName: nibName, bundle: bundle)
        } else {
            self.init(nibName: nil, bundle: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        SLLog.debug("\(self) deinit")
    }
}
