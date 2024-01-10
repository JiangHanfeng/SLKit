//
//  SCLSettingCellModel.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class SCLSettingCellModel: Hashable {
    var image: UIImage?
    var title: String?
    var content: String?
    let id: UUID = UUID()
    
    init(image: UIImage? = nil, title: String? = nil, content: String? = nil) {
        self.image = image
        self.title = title
        self.content = content
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func ==(lhs: SCLSettingCellModel, rhs: SCLSettingCellModel) -> Bool {
            return lhs.id == rhs.id
    }
}
