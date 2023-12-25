//
//  SCLFileRecordCell.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/25.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLFileRecordCell: UITableViewCell {
    
    static let reuseIdentifier = String(describing: SCLFileRecordCell.self)
    
    @IBOutlet private weak var editStateViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var editStateImageView: UIImageView!
    @IBOutlet private weak var typeImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var timeLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var accessoryViewWidthConstraint: NSLayoutConstraint!
    
    
    var showAccessoryView = false
    override var isSelected: Bool {
        didSet {
            editStateImageView.image = UIImage(named: isSelected ? "icon_circle_checked" :"icon_circle_uncheck")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        editStateViewWidthConstraint.constant = editing ? 36 : 0
        accessoryViewWidthConstraint.constant = editing ? 0 : (showAccessoryView ? 12 : 0)
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.layoutIfNeeded()
            } completion: { _ in
                
            }
        }
    }
    
    func setName(_ name: String?) {
        nameLabel.text = name
    }
    
    func setTime(_ time: String?) {
        timeLabel.text = time
        var needUpdate = false
        let lastHeight = timeLabelHeightConstraint.constant
        if let time, !time.isEmpty {
            timeLabelHeightConstraint.constant = 16
        } else {
            timeLabelHeightConstraint.constant = 0
        }
        needUpdate = lastHeight != timeLabelHeightConstraint.constant
        if needUpdate {
            UIView.animate(withDuration: 0.25) {
                self.layoutIfNeeded()
            }
        }
    }
    
    func setImage(_ image: UIImage?) {
        typeImageView.image = image
    }
}
