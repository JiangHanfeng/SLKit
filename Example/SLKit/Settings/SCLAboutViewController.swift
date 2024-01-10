//
//  SCLAboutViewController.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/7/18.
//

import UIKit

class SCLAboutViewController: SCLBaseViewController {

//    private lazy var titleLabel: UILabel = {
//        let label = UILabel(frame: CGRect.zero)
//        label.backgroundColor = .clear
//        label.font = UIFont.font(17,.medium)
//        label.textColor = UIColor.colorWithHex(hexStr: "191919")
//        label.text = NSLocalizedString("SLAboutTitle", comment: "")
//        label.textAlignment = .center
//        return label
//    }()
//    
//    private lazy var backBtn: UIButton = {
//        let btn = UIButton()
//        btn.setBackgroundImage(UIImage.init(named: "back_icon"), for: .normal)
//        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
//        return btn
//    }()
//
//    private lazy var partingLine: UIView = {
//        let line = UIView()
//        line.backgroundColor = UIColor.colorWithHex(hexStr: "#000000", alpha: 0.1)
//        return line
//    }()
    
    private lazy var iconImageView: UIImageView = {
        let img = UIImageView()
        img.image = UIImage.init(named: "icon_setting_app")
        return img
    }()
    
    private lazy var nameLable: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.font = UIFont.font(15,.regular)
//        label.text = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        label.text = "超级互联Lite"
        return label
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 16
        return view
    }()
    
    private lazy var updateLabel:UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.text = NSLocalizedString("SLAboutUpdateTitle", comment: "")
        label.font = UIFont.font(15,.regular)
        return label
    }()
    
    private lazy var moreImageView: UIImageView = {
        let img = UIImageView()
        img.image = UIImage.init(named: "icon_arrow_right")
        return img
    }()
    
    
    private lazy var updateBtn: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        btn.addTarget(self, action: #selector(update), for: .touchUpInside)
        return btn
    }()
    
    
    private lazy var collecteLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.text = NSLocalizedString("SLAboutCollectTitle", comment: "")
        label.font = UIFont.font(15,.regular)
        label.numberOfLines = -1
        return label
    }()

    private lazy var switchView: UISwitch = {
        let switchView = UISwitch()
        switchView.onTintColor = UIColor.colorWithHex(hexStr: "#586CFF")
        switchView.tintColor = UIColor.colorWithHex(hexStr: "#586CFF")
//        switchView.isOn = SLConnectManager.share().collectData()
        switchView.addTarget(self, action: #selector(switchAction), for: .valueChanged)
        return switchView
    }()
    
    private lazy var copyrightLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("SLAboutCopyrightString", comment: "")
        label.textColor = UIColor.colorWithHex(hexStr: "#999999")
        label.font = UIFont.font(10)
        label.numberOfLines = -1
        label.textAlignment = .center
        return label
    }()
    
    
//    private lazy var sourceBtn: UIButton = {
//        let btn = UIButton()
//        btn.setTitle(NSLocalizedString("SLAboutSourceString", comment: ""), for: .normal)
//        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
//        btn.titleLabel?.font = UIFont.font(12)
//        btn.addTarget(self, action: #selector(source), for: .touchUpInside)
//        btn.backgroundColor = .clear
//        return btn
//    }()
    
    
    private lazy var permissionBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLAboutPermissionString", comment: ""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(12)
        btn.addTarget(self, action: #selector(permission), for: .touchUpInside)
        btn.backgroundColor = .clear
        return btn
    }()
    
    
    private lazy var privacyStatementBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLAboutPrivacyStatementString", comment: ""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(12)
        btn.addTarget(self, action: #selector(privacyStatement), for: .touchUpInside)
        btn.backgroundColor = .clear
        return btn
    }()
    
    private lazy var privacyBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLAboutPrivacyString", comment: ""), for: .normal)
        btn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        btn.titleLabel?.font = UIFont.font(12)
        btn.addTarget(self, action: #selector(privacy), for: .touchUpInside)
        btn.backgroundColor = .clear
        return btn
    }()
    
    override func loadView() {
        super.loadView()
        let distanceTop = UIDevice.safeDistanceTop()
        
//        self.view.addSubview(self.titleLabel)
//        self.titleLabel.snp.makeConstraints { make in
//            make.centerX.equalToSuperview()
//            make.top.equalTo(distanceTop + 20)
//        }
//        
//        self.view.addSubview(self.backBtn)
//        self.backBtn.snp.makeConstraints { make in
//            make.centerY.equalTo(self.titleLabel.snp.centerY)
//            make.left.equalTo(20)
//        }
//        
//        self.view.addSubview(self.partingLine)
//        self.partingLine.snp.makeConstraints { make in
//            make.top.equalTo(self.titleLabel.snp.bottom).offset(20)
//            make.height.equalTo(1)
//            make.left.right.equalTo(0)
//        }
//        
        self.view.addSubview(self.iconImageView)
        self.iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.view.snp.top).offset(distanceTop + 84)
        }
        
        
        self.view.addSubview(self.nameLable)
        self.nameLable.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.iconImageView.snp.bottom).offset(20)
        }
        
        self.view.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        
        
        self.contentView.addSubview(self.updateLabel)
        self.updateLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(30)
        }
        
        self.contentView.addSubview(self.moreImageView)
        self.moreImageView.snp.makeConstraints { make in
            make.centerY.equalTo(self.updateLabel.snp.centerY)
            make.right.equalTo(-20)
        }
        
        self.contentView.addSubview(self.updateBtn)
        self.updateBtn.snp.makeConstraints { make in
            make.top.right.left.equalTo(0)
            make.bottom.equalTo(self.updateLabel.snp.bottom).offset(20)
        }
        
        self.contentView.addSubview(self.collecteLabel)
        self.collecteLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(self.updateLabel.snp.bottom).offset(40)
            make.width.equalTo(screenWidth/2.0)
            make.bottom.equalTo(-20)
        }
        
        self.contentView.addSubview(self.switchView)
        self.switchView.snp.makeConstraints { make in
            make.centerY.equalTo(self.collecteLabel.snp.centerY)
            make.right.equalTo(-30)
        }
        
        self.view.addSubview(self.copyrightLabel)
        self.copyrightLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-50)
        }
        
        
        self.view.addSubview(self.permissionBtn)
        self.permissionBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.copyrightLabel.snp.top).offset(-20)
            make.height.equalTo(30)
            make.width.equalTo(100)
            make.centerX.equalToSuperview().offset(0)
        }
        
//        self.view.addSubview(self.sourceBtn)
//        self.sourceBtn.snp.makeConstraints { make in
//            make.bottom.equalTo(self.copyrightLabel.snp.top).offset(-20)
//            make.height.equalTo(30)
//            make.width.equalTo(80)
//            make.left.equalTo(self.permissionBtn.snp.right)
//        }
        
        
        self.view.addSubview(self.privacyBtn)
        self.privacyBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.permissionBtn.snp.top)
            make.height.equalTo(30)
            make.width.equalTo(50)
            make.centerX.equalToSuperview().offset(-50)
        }
        
        self.view.addSubview(self.privacyStatementBtn)
        self.privacyStatementBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.permissionBtn.snp.top)
            make.height.equalTo(30)
            make.width.equalTo(100)
            make.left.equalTo(self.privacyBtn.snp.right)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor =  UIColor.colorWithHex(hexStr: "#f7f7f7", alpha: 1)
    }
    
    @objc
    func back(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc
    func update(){
//        SLAnalyticsManager.share().updateAppAnalytics()
    }

    @objc
    func switchAction(){
//        SLConnectManager.share().setCollectData(self.switchView.isOn)
//        SLAnalyticsManager.share().setEnable(self.switchView.isOn)
    }
    
    @objc
    func privacyStatement(){
        let vc = SLWebViewController(NSLocalizedString("SLPrivacyStatementTitle", comment: ""), "https://www.lenovo.com/privacy/")
        self.navigationController?.present(vc, animated: true)
    }
    
    @objc
    func privacy(){
        let vc = SLWebViewController(NSLocalizedString("SLPrivacyTitle", comment: ""), "https://tb-tst5.lenovo.com/privacy/")
        self.navigationController?.present(vc, animated: true)
    }
    
    @objc
    func permission(){
        let vc = SLWebViewController(NSLocalizedString("SLPermissionTitle", comment: ""), "https://support.lenovo.com/us/en/solutions/ht100141")
        self.navigationController?.present(vc, animated: true)
    }
    
    @objc
    func source(){
//        let vc = SLWebViewController(NSLocalizedString("SLSourceTitle", comment: ""),AppInfo.sourceUrl())
//        self.navigationController?.present(vc, animated: true)
    }

}
