//
//  SCLPhonePickerCell.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/24.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLPhonePickerCell: UITableViewCell {

    static let reuseIdentifier = "SCLPhonePickerCell"
    
    @IBOutlet weak var iconView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verifyLabel: UILabel!
    
    private lazy var progressBackgroundLayer = {
        return CAShapeLayer()
    }()
    private lazy var progressLayer = {
        return CAShapeLayer()
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        verifyLabel.text = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func setProgress(_ progress: CGFloat, result: Bool?) {
        
        if progressBackgroundLayer.superlayer == nil {
            // ps: 圆心+0.33的原因是因为图标素材不是1:1的，需要调整圆心看上去进度条和图标的间距才近似处处相等
            let path = UIBezierPath(arcCenter: CGPoint(x: iconView.bounds.width / 2.0 + 0.33, y: iconView.bounds.width / 2.0 + 0.33), radius: iconView.bounds.width / 2.0 - 2, startAngle: -Double.pi * 0.5, endAngle: Double.pi * 1.5, clockwise: true)
            progressBackgroundLayer.path = path.cgPath
            progressBackgroundLayer.lineWidth = 1
            progressBackgroundLayer.strokeColor = UIColor(red: 216/255.0, green: 216/255.0, blue: 216/255.0, alpha: 1).cgColor
            progressBackgroundLayer.fillColor = UIColor.clear.cgColor
            iconView.layer.addSublayer(progressBackgroundLayer)
        }
        if progressLayer.superlayer == nil {
            let path = UIBezierPath(arcCenter: CGPoint(x: iconView.bounds.width / 2.0 + 0.33, y: iconView.bounds.width / 2.0 + 0.33), radius: iconView.bounds.width / 2.0 - 2, startAngle: -Double.pi * 0.5, endAngle: Double.pi * 1.5, clockwise: true)
            progressLayer.path = path.cgPath
            progressLayer.lineWidth = 1
            progressLayer.strokeColor = UIColor(red: 54/255.0, green: 120/255.0, blue: 1, alpha: 1).cgColor
            progressLayer.fillColor = UIColor.clear.cgColor
            progressLayer.lineCap = CAShapeLayerLineCap.round
            iconView.layer.addSublayer(progressLayer)
        }
        progressBackgroundLayer.isHidden = progress == 0
        progressLayer.isHidden = progress == 0
        progressLayer.strokeEnd = progress
        
        if let result {
            verifyLabel.text = result ? "验证通过" : "验证未通过"
        } else {
            verifyLabel.text = nil
        }
    }
}
