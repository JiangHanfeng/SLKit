//
//  SLReceivingFileTableViewCell.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/8/24.
//

import UIKit

class SLReceivingFileTableViewCell: UITableViewCell {
    
    private var cancelBlock:(()->Void)?
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 16
        return view
    }()
    
    private lazy var imgView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "folder_file_icon")
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.font = UIFont.font(15)
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var progressView : UIProgressView = {
        let progressView = UIProgressView()
        return progressView
    }()
    
    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#666666")
        label.font = UIFont.font(12)
        return label
    }()
    
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.setBackgroundImage(UIImage.init(named: "concel_file_icon"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return cancelButton
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        
        self.contentView.addSubview(self.backView)
        self.backView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalTo(-10)
            make.top.equalTo(0)
            make.height.equalTo(80)
        }
        
        self.backView.addSubview(self.imgView)
        self.imgView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        self.backView.addSubview(self.cancelButton)
        self.cancelButton.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
        }
        
        self.backView.addSubview(self.progressView)
        self.progressView.snp.makeConstraints { make in
            make.left.equalTo(self.imgView.snp.right).offset(10)
            make.width.equalTo(screenWidth - 150)
            make.top.equalTo(self.backView.snp.centerY)
        }
        
        self.backView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.imgView.snp.right).offset(10)
            make.width.equalTo(screenWidth - 150)
            make.bottom.equalTo(self.progressView.snp.centerY).offset(-5)
        }
        
        self.backView.addSubview(self.subTitleLabel)
        self.subTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.imgView.snp.right).offset(10)
            make.top.equalTo(self.progressView.snp.bottom).offset(5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showFile(_ fileModels: SLFileTransferModel) {
        self.setProgress(fileModels.currentProgress)
        if fileModels.files.count == 1 {
            let fileModel = fileModels.files[0];
            self.titleLabel.text = String.init(format: NSLocalizedString("SLFileReceivingFileString", comment: ""),fileModel.fullFileNama(),fileModels.files.count)
            let type = fileModel.fileType()
            if type == .folderFileType {
                self.imgView.image = UIImage.init(named: "folder_file_icon")
            } else if type == .videoFileType {
                self.imgView.image = UIImage.init(named: "video_file_icon")
            } else if type == .imageFileType {
                self.imgView.image = UIImage.init(named: "image_file_icon")
            } else if type == .audioFileType {
                self.imgView.image = UIImage.init(named: "audio_file_icon")
            } else if type == .excelFileType {
                self.imgView.image = UIImage.init(named: "excel_file_icon")
            } else if type == .pdfFileType {
                self.imgView.image = UIImage.init(named: "pdf_file_icon")
            } else if type == .wordFileType {
                self.imgView.image = UIImage.init(named: "word_file_icon")
            } else if type == .pptFileType {
                self.imgView.image = UIImage.init(named: "ppt_file_icon")
            } else if type == .zipFileType {
                self.imgView.image = UIImage.init(named: "zip_file_icon")
            } else if type == .txtFileType {
                self.imgView.image = UIImage.init(named: "txt_file_icon")
            }else {
                self.imgView.image = UIImage.init(named: "unknown_file_icon")
            }
        } else {
            self.imgView.image = UIImage.init(named: "more_file_icon")
            let fileModel = fileModels.files[0];
            let test = String.init(format: NSLocalizedString("SLFileReceivingFileString", comment: ""),fileModel.fullFileNama(),fileModels.files.count)
            self.titleLabel.text = test
        }
    }
    
    @objc
    func setProgress(_ progress : Float){
        self.progressView.progress = progress
        self.subTitleLabel.text = "\(String.init(format: "%.0f", progress*100))%"
    }
    
    @objc
    func cancel(){
        self.cancelBlock?()
    }

    func setCancelBlock( _ block:@escaping ()->Void){
        self.cancelBlock = block
    }
}
