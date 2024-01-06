//
//  SLFileListTableViewCell.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/6/12.
//

import UIKit

class SLFileListTableViewCell: UITableViewCell {
    
    var editBlock:(()->Void)?
    
    private var isEdit = false
    
    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 16
        var longpressGesutre = UILongPressGestureRecognizer(target: self, action: #selector(handleLongpressGesture))
        longpressGesutre.minimumPressDuration = 0.5
        view.addGestureRecognizer(longpressGesutre)
        return view
    }()
    
    private lazy var selectImgView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "noselect_icon")
        return imageView
    }()
    
    private lazy var imgView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "folder_file_icon")
        return imageView
    }()
    
    private lazy var titleLabel: UIButton = {
        let label = UIButton()
        label.setTitleColor(UIColor.colorWithHex(hexStr: "#191919"), for: .normal)
        label.titleLabel?.font = UIFont.font(15)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#666666")
        label.font = UIFont.font(12)
        return label
    }()
    
    private lazy var moreImgView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "list_more_icon")
        return imageView
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
        
        self.backView.addSubview(self.selectImgView)
        self.selectImgView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        self.backView.addSubview(self.imgView)
        self.imgView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        self.backView.addSubview(self.moreImgView)
        self.moreImgView.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
        }
        
        self.backView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.right.lessThanOrEqualToSuperview().offset(-20)
            make.left.equalTo(self.imgView.snp.right).offset(10)
            make.bottom.equalTo(self.backView.snp.centerY).offset(5)
        }
        
        self.backView.addSubview(self.subTitleLabel)
        self.subTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.imgView.snp.right).offset(10)
            make.top.equalTo(self.backView.snp.centerY).offset(5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func edit(_ isEdit: Bool,_ isFolder: Bool ) {
        
        self.selectImgView.isHidden = !isEdit
        
        self.selectImgView.snp.remakeConstraints { make in
            if isEdit {
                make.width.height.equalTo(20)
            } else {
                make.width.height.equalTo(0)
            }
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        self.backView.addSubview(self.imgView)
        self.imgView.snp.remakeConstraints { make in
            if isEdit {
                make.left.equalTo(self.selectImgView.snp.right).offset(10)
            } else {
                make.left.equalTo(20)
            }
            make.width.height.equalTo(36)
            make.centerY.equalToSuperview()
        }
        
        if isEdit {
            self.moreImgView.isHidden = true
        } else {
            self.moreImgView.isHidden = isFolder == false
        }
    }
    
    func selectFile( _ ret: Bool) {
        self.isEdit = ret
        self.selectImgView.image = ret ?  UIImage.init(named: "select_icon") :  UIImage.init(named: "noselect_icon")
    }
    
    func showFile(_ fileModel: SLFileModel) {
        
        self.titleLabel.setTitle("\(fileModel.name).\(fileModel.extensionName)", for: .normal)
        
        let date = Date.init(timeIntervalSince1970: Double(fileModel.time))
        let  dateFormater = DateFormatter.init()
        dateFormater.dateFormat = "YYYY.MM.dd"
        let dateStr = dateFormater.string(from: date)
        self.subTitleLabel.text = dateStr
    
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
    }
    
    @objc
    func handleLongpressGesture(){
        if self.isEdit {
            return
        }
        self.editBlock?()
    }
}
