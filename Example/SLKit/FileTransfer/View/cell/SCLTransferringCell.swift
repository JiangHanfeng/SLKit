//
//  SCLTransferringCell.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2024/1/7.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

//struct SCLTransferringModel {
//    let taskId: String
//    let type: SCLFileTransferType
//    var name: String
//    var count: Int
//    var progress: Float
//    
//    init(taskId: String, type: SCLFileTransferType, name: String, count: Int, progress: Float) {
//        self.taskId = taskId
//        self.type = type
//        self.name = name
//        self.count = count
//        self.progress = progress
//    }
//}
//
//struct SCLTransferringCellModel {
//    let image = BehaviorRelay<UIImage?>(value: nil)
//    let name = BehaviorRelay<String?>(value: nil)
//    let status = BehaviorRelay<String?>(value: nil)
//    let progress = BehaviorRelay<Float>(value: 0)
//    
//    init(model: SCLTransferringModel) {
//        
//    }
//}

class SCLTransferringCell: UITableViewCell {

    static let reuseIdentifier = String(describing: SCLTransferringCell.self)
    
    @IBOutlet private weak var typeImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var statusLabel: UILabel!
    
    private var onCanceled: (() -> Void)?
    
//    private var disposeBag = DisposeBag()
//    
//    let openSubject = PublishSubject<Void>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

//    override func prepareForReuse() {
//        super.prepareForReuse()
//        disposeBag = DisposeBag()
//    }
    
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
