//
//  SLFileOperateModel.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/7/14.
//

import UIKit

class SLFileOperateModel: NSObject {
    var isSelect = false
    var fileModel: SLFileModel?

    static func model(_ fileModel: SLFileModel) -> SLFileOperateModel {
        let model = SLFileOperateModel()
        model.fileModel = fileModel
        return model
    }
}
