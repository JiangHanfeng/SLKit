//
//  SLAdjustingOpenTouchView.swift
//  OMNIEnjoy
//
//  Created by shenjianfei on 2024/1/5.
//

import UIKit

class SLAdjustingOpenTouchView: UIView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        
        let str1 = NSLocalizedString("SLAdjustingStratContentHindString1", comment: "")
        let str2 = NSLocalizedString("SLAdjustingStratContentHindString2", comment: "")
        let str3 = NSLocalizedString("SLAdjustingStratContentHindString3", comment: "")
        
        let content = "\(str1)\(str2)\(str3)"
        
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.35
        style.alignment = .center

        let contentAttributedString = NSMutableAttributedString(string: content,attributes:[NSAttributedString.Key.paragraphStyle: style])
    
        let range1 = NSMakeRange(0, str1.count)
        contentAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.font(14,.regular), range: range1)

        let range2 = NSMakeRange(str1.count, str2.count)
        contentAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.font(14,.bold), range: range2)

        let range3 = NSMakeRange(str1.count + str2.count, str3.count)
        contentAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.font(14,.regular), range: range3)
        
        label.attributedText = contentAttributedString
        
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.font(13,.regular)
        label.textColor = UIColor.colorWithHex(hexStr: "#ffffff",alpha: 0.6)
        label.numberOfLines = -1
        label.textAlignment = .center
        
        let content = NSLocalizedString("SLAdjustingStratSubContentHindString", comment: "")
        
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.35
        style.alignment = .center

        let contentAttributedString = NSMutableAttributedString(string: content,attributes:[NSAttributedString.Key.paragraphStyle: style])
        
        label.attributedText = contentAttributedString
        
        return label
    }()
    
    private lazy var settingBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLAdjustingStratGoSystemTitleString", comment: ""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#446BFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(15,.medium)
        btn.addTarget(self, action: #selector(goSetting), for: .touchUpInside)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.colorWithHex(hexStr: "#FFFFFF",alpha: 0.12)
        
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.colorWithHex(hexStr: "#335EFF").cgColor
        
        self.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.top.left.equalTo(16)
            make.right.equalTo(-16)
        }
        
        self.addSubview(self.subtitleLabel)
        self.subtitleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
        }
        
        self.addSubview(self.settingBtn)
        self.settingBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.subtitleLabel.snp.bottom).offset(8)
            make.bottom.equalTo(-16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func goSetting(){
        guard let url = URL(string: "App-Prefs:root=")  else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
