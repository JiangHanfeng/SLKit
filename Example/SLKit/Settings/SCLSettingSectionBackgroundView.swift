//
//  SCLSettingSectionBackgroundView.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLSettingSectionBackgroundView: UICollectionReusableView {
    static let reuseIdentifier = String(describing: SCLSettingSectionBackgroundView.self)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.masksToBounds = true
        layer.cornerRadius = 16
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
