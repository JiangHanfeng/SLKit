//
//  SCLDeviceViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLDeviceViewController: UIViewController {

//    @IBOutlet weak var deviceIconView: UIView!
    @IBOutlet weak var disconenctBtn: UIButton!
    
    private var disconnectedCallback: (() -> Void)?
    
    convenience init(_ disconnectedCallback: @escaping () -> Void) {
        self.init(nibName: "SCLDeviceViewController", bundle: Bundle.main)
        self.disconnectedCallback = disconnectedCallback
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        deviceIconView.setGradientBackgroundColors(colors: [
//            UIColor(red: 111/255.0, green: 129/255.0, blue: 1, alpha: 1),
//            UIColor(red: 71/255.0, green: 93/255.0, blue: 241/255.0, alpha: 1)
//        ], locations: [NSNumber(value: 0), NSNumber(value: 1)])
        
        disconenctBtn.setBorder(width: 1, cornerRadius: 15, color: UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1))
    }


    @IBAction private func onDisconnect() {
//        disconnectedCallback?()
//        present(SCLPairViewController(), animated: true)
        present(SCLAirPlayGuideViewController(), animated: true)
    }

}
