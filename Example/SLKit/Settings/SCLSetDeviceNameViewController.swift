//
//  SCLSetDeviceNameViewController.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/7/6.
//

import UIKit

class SCLSetDeviceNameViewController: SCLBaseViewController {
    
    var updataNameBlock:((String)->Void)?
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 16
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr:"#191919")
        label.text = NSLocalizedString("SLSettingSetDeviceNameTitle", comment: "")
        label.font = UIFont.font(15,.medium)
        return label
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("SLSettingSetDeviceNamePlaceholderTitle", comment: "")
        textField.text = SCLUtil.getDeviceName()
        textField.delegate = self
        textField.addTarget(self, action: #selector(keyboardInputShouldDelete(_:)), for: .editingChanged)
        return textField
    }()
    
    private lazy var textFieldBackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.colorWithHex(hexStr: "#EDEDED")
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var errLabel: UITextView = {
        let label = UITextView()
        label.backgroundColor = .clear
        label.textColor = UIColor.colorWithHex(hexStr: "#F04D58")
        label.text = NSLocalizedString("SLSettingSetDeviceNameErrorString", comment: "")
        label.font = UIFont.font(12)
        label.isUserInteractionEnabled = false
        label.isHidden = true
        return label
    }()
    
    private lazy var lineView1: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.colorWithHex(hexStr: "#E5E5E5")
        return view
    }()
    
    private lazy var lineView2: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.colorWithHex(hexStr: "#E5E5E5")
        return view
    }()
    
    private lazy var cancelBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLCancelTitle", comment:""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(15)
        btn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        btn.backgroundColor = .clear
        return btn
    }()
    
    private lazy var affirmBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLAffirmTitle", comment:""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(15)
        btn.addTarget(self, action: #selector(affirm), for: .touchUpInside)
        btn.backgroundColor = .clear
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
        self.contentView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.centerY.equalTo(screenHeight/3.0)
        }
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.centerX.equalToSuperview()
        }
        
        self.contentView.addSubview(self.textFieldBackView)
        self.textFieldBackView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        
        self.textFieldBackView.addSubview(self.textField)
        self.textField.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.bottom.equalTo(-10)
            make.height.equalTo(30)
        }
        
        self.contentView.addSubview(self.errLabel)
        self.errLabel.snp.makeConstraints { make in
            make.top.equalTo(self.textFieldBackView.snp.bottom)
            make.left.equalTo(25)
            make.right.equalTo(-25)
            make.height.equalTo(50)
        }
        
        self.contentView.addSubview(self.lineView1)
        self.lineView1.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(self.errLabel.snp.bottom).offset(10)
        }
        
        self.contentView.addSubview(self.lineView2)
        self.lineView2.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(52)
            make.top.equalTo(self.lineView1.snp.bottom)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(0)
        }
        
        
        self.contentView.addSubview(self.cancelBtn)
        self.cancelBtn.snp.makeConstraints { make in
            make.bottom.left.equalTo(0)
            make.top.equalTo(self.lineView1.snp.bottom)
            make.right.equalTo(self.lineView2.snp.left)
        }
        
        self.contentView.addSubview(self.affirmBtn)
        self.affirmBtn.snp.makeConstraints { make in
            make.bottom.right.equalTo(0)
            make.top.equalTo(self.lineView1.snp.bottom)
            make.left.equalTo(self.lineView2.snp.right)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.textField.becomeFirstResponder()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.textField.resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.colorWithHex(hexStr: "#000000", alpha: 0.6)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismiss(animated: false)
    }
    
    @objc
    func cancel(){
        self.dismiss(animated: false)
    }
    
    @objc
    func affirm(){
        
        let test = (self.textField.text ?? "").removeHeadAndTailSpacePro
        if test.count == 0 {
            return
        }
        
        guard let gbkData = test.data(using: self.encoding()),
              gbkData.count <= 32 else {
            return
        }
        
        _ = SCLUtil.setDeviceName(test)
        self.dismiss(animated: false) {
            self.updataNameBlock?(test)
        }
    }

   @objc
   fileprivate func keyboardInputShouldDelete(_ textField: UITextField){
       guard let text = textField.text,
             text.count > 0 else {
           return
       }
       guard let gbkData = text.data(using: self.encoding()) else {
           return
       }
       self.errLabel.isHidden = gbkData.count <= 32
   }
    
    fileprivate func encoding() -> String.Encoding {
        let cfEncoding = CFStringEncodings.GB_18030_2000
        let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
        return String.Encoding(rawValue: encoding)
    }
}

extension SCLSetDeviceNameViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text,
           let textRange = Range(range, in: text) {
           let updatedText = text.replacingCharacters(in: textRange, with: string)
            if updatedText.containsEmoji {
                return false
            }
        }
        return true
    }
}

