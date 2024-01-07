//
//  SCLTransferringCell.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/7.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

class SCLTransferringCell: UITableViewCell {

    static let reuseIdentifier = String(describing: SCLTransferringCell.self)
    
    @IBOutlet private weak var typeImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var statusLabel: UILabel!
    
    private var onCanceled: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction private func onCancel() {
        self.onCanceled?()
    }
    
    func set(imageName: String, name: String, status: String, progress: Float, onCanceled: @escaping (() -> Void)) {
        self.typeImageView.image = UIImage(named: imageName)
        self.nameLabel.text = name
        self.statusLabel.text = status
        self.progressView.progress = progress
        self.onCanceled = onCanceled
    }
}
