//
//  SCLAirPlayGuideViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/24.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLAirPlayGuideViewController: SCLBaseViewController {

    @IBOutlet private weak var cancelBtn: UIButton!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelBtn.setBorder(width: 1, cornerRadius: 22, color: UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1))
    }
    
    @IBAction func onCancel(sender: UIButton) {
        dismiss(animated: true)
    }
}
