//
//  SLReceiveFileProgressView.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/6/12.
//

import UIKit

class SLReceiveFileProgressView: UIView {
    
    var cancelBlock:(()->Void)?

    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("SLFileReceivingFileString", comment: "")
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.font = UIFont.font(15,.medium)
        return label
    }()
    
    private lazy var cancelBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLCancelTitle", comment:""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(15)
        btn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return btn
    }()
    
    private lazy var progressView : UIProgressView = {
        let label = UIProgressView()
        return label
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.colorWithHex(hexStr: "#E5E5E5")
        return view
    }()
    
    private lazy var percentLabel : UILabel = {
        let label = UILabel()
        label.text = "\(0)%"
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.font = UIFont.font(15,.regular)
        return label
    }()

    func load(){
       
        self.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(40)
        }
        
        self.addSubview(self.progressView)
        self.progressView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(20)
        }
        
        self.addSubview(self.percentLabel)
        self.percentLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.progressView.snp.bottom).offset(20)
        }

        self.addSubview(self.cancelBtn)
        self.cancelBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(0)
            make.height.equalTo(50)
            make.width.equalToSuperview()
        }
        
        self.addSubview(self.lineView)
        self.lineView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalTo(self.cancelBtn.snp.top)
        }
    }
    
    func setTitle(_ title: String) {
        
    }
    
    func setProgress(_ pro:Float) {
        self.percentLabel.text = "\(String.init(format: "%.0f", pro * 100))%"
        self.progressView.progress = pro
    }

    @objc
    func cancel(){
        self.cancelBlock?()
    }
}
