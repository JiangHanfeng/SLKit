//
//  SCLAlertViewController.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/7/23.
//

import UIKit

enum SLAlertViewControllerType {
    case succee
    case error
    case select
    case warn
}

class SCLAlertViewController: SCLBaseViewController {
    
    var finishBlock:((Bool)->Void)?
    
    private var titleString: String = ""
    private var descString: String?
    private var okString: String?
    private var noString: String?
    private var type: SLAlertViewControllerType = .succee
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 16
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        if(self.type == .succee) {
            imageView.image =  UIImage.init(named: "alert_success_icon")
        } else if(self.type == .warn) {
            imageView.image =  UIImage.init(named: "alert_warn_icon")
        } else {
            imageView.image =  UIImage.init(named: "alert_error_icon")
        }
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = self.titleString
        label.textColor = UIColor.black
        label.font = UIFont.font(15, .semibold)
        label.textAlignment = .center
        label.numberOfLines = -1
        return label
    }()
    
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.text = self.descString
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.font = UIFont.font(13)
        label.textAlignment = .center
        label.numberOfLines = -1
        return label
    }()
    
    private lazy var offBtn: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        btn.setTitle(self.noString, for: .normal)
        btn.titleLabel?.font = UIFont.font(15)
        return btn
    }()
    
    private lazy var okBtn: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(ok), for: .touchUpInside)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        btn.setTitle(self.okString, for: .normal)
        btn.titleLabel?.font = UIFont.font(15)
        return btn
    }()
    
    init(_ type: SLAlertViewControllerType,
         _ title:String,
         _ noBtn:String?,
         _ okBtn:String?,
         _ desc: String? = nil
    ) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.titleString = title
        self.type = type
        self.okString = okBtn
        self.noString = noBtn
        self.descString = desc
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            if UIDevice.isPad() {
                make.width.equalTo(300)
            } else {
                make.left.equalTo(20)
                make.right.equalTo(-20)
            }
            make.center.equalToSuperview()
        }
        
        if !(self.type == .select || self.type == .warn) {
            self.contentView.addSubview(self.iconImageView)
            self.iconImageView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(20)
            }
        }
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            if !(self.type == .select || self.type == .warn) {
                make.top.equalTo(self.iconImageView.snp.bottom).offset(20)
            } else {
                make.top.equalTo(50)
            }
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        self.contentView.addSubview(self.descLabel)
        let distanceBetweenDescAndTitle = (descString?.count ?? 0) > 0 ? 20 : 0
        self.descLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(distanceBetweenDescAndTitle)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        if self.type == .select || self.type == .warn {
            
            let lineview = UIView()
            lineview.backgroundColor = UIColor.colorWithHex(hexStr: "#E5E5E5")
            self.contentView.addSubview(lineview)
            lineview.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
                make.width.equalTo(1)
                make.height.equalTo(52)
            }
            
            self.contentView.addSubview(self.offBtn)
            self.offBtn.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalTo(lineview.snp.left)
                make.top.equalTo(self.descLabel.snp.bottom).offset(50)
                make.bottom.equalTo(0)
                make.height.equalTo(52)
            }
            
            self.contentView.addSubview(self.okBtn)
            self.okBtn.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.left.equalTo(lineview.snp.right)
                make.top.equalTo(self.descLabel.snp.bottom).offset(50)
                make.bottom.equalTo(0)
                make.height.equalTo(52)
            }
            
        } else {
            self.contentView.addSubview(self.okBtn)
            self.okBtn.snp.makeConstraints { make in
                make.right.left.equalToSuperview()
                make.top.equalTo(self.descLabel.snp.bottom).offset(33)
                make.bottom.equalTo(0)
                make.height.equalTo(52)
            }
        }
        
        let lineview = UIView()
        lineview.backgroundColor = UIColor.colorWithHex(hexStr: "#E5E5E5")
        self.contentView.addSubview(lineview)
        lineview.snp.makeConstraints { make in
            make.right.left.equalToSuperview()
            make.bottom.equalTo(self.okBtn.snp.top)
            make.height.equalTo(1)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.colorWithHex(hexStr: "#000000",alpha: 0.6)
    }
    
    @objc
    func back(){
        self.dismiss(animated: false){
            self.finishBlock?(false)
        }
    }
    
    @objc
    func ok(){
        self.dismiss(animated: false){
            self.finishBlock?(true)
        }
    }
}
