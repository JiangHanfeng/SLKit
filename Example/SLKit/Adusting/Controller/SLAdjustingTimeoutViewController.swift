//
//  SLAdjustingTimeoutViewController.swift
//  OMNIEnjoy
//
//  Created by shenjianfei on 2024/1/5.
//

import UIKit

class SLAdjustingTimeoutViewController: UIViewController {

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.font(15,.medium)
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.textAlignment = .center
        label.text = NSLocalizedString("SLAdjustingTimeoutHintString", comment: "")
        return label
    }()
    
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.font(14,.regular)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = -1
                
        let str1 = NSLocalizedString("SLAdjustingTimeoutHintContentString1", comment: "")
        let str2 = NSLocalizedString("SLAdjustingTimeoutHintContentString2", comment: "")
        let str3 = NSLocalizedString("SLAdjustingTimeoutHintContentString3", comment: "")
        let str4 = NSLocalizedString("SLAdjustingTimeoutHintContentString4", comment: "")
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        style.alignment = .center
        let attr = NSMutableAttributedString(string: "\(str1)\(str2)\(str3)\(str4)", attributes: [NSAttributedString.Key.paragraphStyle: style])
        attr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.colorWithHex(hexStr: "#262626"), range: NSRange.init(location: 0, length: str1.count))
        attr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.colorWithHex(hexStr: "#335EFF"), range: NSRange.init(location: str1.count, length: str2.count))
        attr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.colorWithHex(hexStr: "#262626"), range: NSRange.init(location: str1.count + str2.count, length: str3.count))
        attr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.colorWithHex(hexStr: "#335EFF"), range: NSRange.init(location: str1.count + str2.count + str3.count, length: str4.count))
        label.attributedText = attr
        return label
    }()
    
    
    private lazy var cancelBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLCancelTitle", comment: ""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#335EFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(15,.regular)
        btn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return btn
    }()
    
    private lazy var settingBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLAdjustingTimeoutHintSettingTitle", comment: ""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#335EFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(15,.regular)
        btn.addTarget(self, action: #selector(setting), for: .touchUpInside)
        return btn
    }()
    

    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.addSubview(self.contentView)
        self.contentView.snp.remakeConstraints { make in
            if UIDevice.isPad() {
                make.width.equalTo(300)
            } else {
                make.left.equalTo(20)
                make.right.equalTo(-20)
            }
            make.center.equalToSuperview()
        }
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
        }
        
        self.contentView.addSubview(self.contentLabel)
        self.contentLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(20)
        }
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor.colorWithHex(hexStr: "#EDEDED")
        self.contentView.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.top.equalTo(self.contentLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
            make.width.equalToSuperview()
        }
        
        let lineView1 = UIView()
        lineView1.backgroundColor = UIColor.colorWithHex(hexStr: "#EDEDED")
        self.contentView.addSubview(lineView1)
        lineView1.snp.makeConstraints { make in
            make.top.equalTo(lineView.snp.bottom)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(60)
            make.width.equalTo(1)
        }

        self.contentView.addSubview(self.settingBtn)
        self.settingBtn.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalTo(lineView1.snp.left)
            make.top.equalTo(lineView.snp.bottom)
            make.bottom.equalToSuperview()
        }

        self.contentView.addSubview(self.cancelBtn)
        self.cancelBtn.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(lineView1.snp.right)
            make.top.equalTo(lineView.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
    
    @objc
    func cancel(){
        self.dismiss(animated: false)
    }
    
    @objc
    func setting(){
        self.dismiss(animated: false){
            guard let url = URL(string:"App-Prefs:root="), UIApplication.shared.canOpenURL(url) else {
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    
    
    
    
}
