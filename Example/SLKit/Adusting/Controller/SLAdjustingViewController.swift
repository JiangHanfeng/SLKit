//
//  SLAdjustingViewController.swift
//  OMNIEnjoy
//
//  Created by shenjianfei on 2023/11/15.
//

import UIKit

fileprivate enum SLAdjustingStatusType {
    case start
    case horizontalOri
    case verticalOri
    case prepareAdjusting
    case adjusting
    case succeed
    case fail
}

class SLAdjustingViewController: UIViewController {
    
    private lazy var status: SLAdjustingStatusType = .start
    var dismissBlock:(()->Void)?
    private var isInitiative = false
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = .clear
        label.font = UIFont.font(17,.medium)
        label.textColor = .white
        label.text = NSLocalizedString("SLAdjustingtitleString", comment: "")
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage.init(named: "off_white_icon"), for: .normal)
        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
        return btn
    }()
    
    private lazy var adjustingView: SLAdjustingView = {
        let view = SLAdjustingView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()
        
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "adjusting_prepare_icon")
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    
    private lazy var horImageView: SLAdjustingImageView = {
        let imageView = SLAdjustingImageView()
        var imags: [UIImage] = []
        for i in 0..<13 {
            if let img = UIImage.init(named: "adjusting_hor_icon_\(i+1)") {
                imags.append(img)
            }
        }
        imageView.animationImages = imags
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private lazy var verImageView: SLAdjustingImageView = {
        let imageView = SLAdjustingImageView()
        var imags: [UIImage] = []
        for i in 0..<13 {
            if let img = UIImage.init(named: "adjusting_ver_icon_\(i+1)") {
                imags.append(img)
            }
        }
        imageView.animationImages = imags
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private lazy var adjustingImageView: UIImageView = {
        let imageView = UIImageView()
        var imags: [UIImage] = []
        for i in 0..<24 {
            if let img = UIImage.init(named: "adjusting_adjusting_icon_\(i+1)") {
                imags.append(img)
            }
        }
        imageView.animationImages = imags
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private lazy var hintContentBackView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.font(16,.medium)
        label.numberOfLines = -1
        label.textAlignment = .center
        return label
    }()
    
    private lazy var hintContentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.font(14,.regular)
        label.numberOfLines = -1
        label.textAlignment = .center
        return label
    }()
    
    private lazy var openTouchView:SLAdjustingOpenTouchView = {
        return SLAdjustingOpenTouchView()
    }()
    
    private lazy var adjustingSortView: SLAdjustingSortView = {
        let view = SLAdjustingSortView(frame: CGRect.zero)
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var statusBtn: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.font(15)
        btn.backgroundColor = UIColor.colorWithHex(hexStr: "#335EFF")
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 24
        btn.addTarget(self, action: #selector(btnPrssed), for: .touchUpInside)
        return btn
    }()
    
    init(_ initiative: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.isInitiative = initiative
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        let distanceTop = UIDevice.safeDistanceTop()
        let distanceBottom = UIDevice.safeDistanceBottom()
        
        self.view.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(distanceTop + 40)
        }
        
        self.view.addSubview(self.adjustingView)
        self.adjustingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.view.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.snp.centerY).offset(-40)
        }
        
        self.view.addSubview(self.horImageView)
        self.horImageView.snp.makeConstraints { make in
            make.center.equalTo(self.imageView.snp.center)
        }
        
        self.view.addSubview(self.verImageView)
        self.verImageView.snp.makeConstraints { make in
            make.center.equalTo(self.imageView.snp.center)
        }
        
        self.view.addSubview(self.adjustingImageView)
        self.adjustingImageView.snp.makeConstraints { make in
            make.center.equalTo(self.imageView.snp.center)
        }
        
        self.view.addSubview(self.hintContentBackView)
        self.hintContentBackView.snp.makeConstraints { make in
            make.left.equalTo(40)
            make.right.equalTo(-40)
            make.top.equalTo(self.imageView.snp.bottom).offset(15)
        }
        
        self.hintContentBackView.addSubview(self.hintLabel)
        self.hintLabel.snp.makeConstraints { make in
            make.left.right.equalTo(0)
            make.top.equalTo(10)
        }
        
        self.hintContentBackView.addSubview(self.hintContentLabel)
        self.hintContentLabel.snp.makeConstraints { make in
            make.left.right.equalTo(0)
            make.top.equalTo(self.hintLabel.snp.bottom).offset(20)
        }
        
        self.hintContentBackView.addSubview(self.openTouchView)
        self.openTouchView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.top.equalTo(self.hintContentLabel.snp.bottom).offset(20)
        }
        
        self.hintContentBackView.addSubview(self.adjustingSortView)
        self.adjustingSortView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.hintContentLabel.snp.bottom).offset(40)
            make.bottom.equalTo(-10)
        }
        
        self.view.addSubview(self.statusBtn)
        self.statusBtn.snp.makeConstraints { make in
            make.width.equalTo(300)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-(distanceBottom + 80))
        }
        
        self.view.addSubview(self.backBtn)
        self.backBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel.snp.centerY)
            make.right.equalTo(-20)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.backgroundColor = UIColor.colorWithHex(hexStr: "#000000", alpha: 0.9)
        self.upView()
        
        self.adjustingView.adjustingLeftOrRightOrientationCompleteBlock = {[weak self] in
            self?.status = .verticalOri
            self?.upView()
        }

        self.adjustingView.adjustingOrientationCompleteBlock = { [weak self] in
            self?.adjustingView.endAdjustingOrientation()
            self?.status = .prepareAdjusting
            self?.upView()
        }
        
        
        //断开连接通知
//        NotificationCenter.default.addObserver(self, selector: #selector(disconnectDevice), name:Notification.Name(K_Notice_Disonnect), object: nil)
        
        //触控过大  SLAdjustingControlManager 里的 adjustingSensitivityBigBlock
//        SLConnectManager.share().adjustingSensitivityBigBlock = {[weak self]  dev in
//            self?.present(SLAdjustingSensitivityBigHintViewController(), animated: false)
//        }
        
         //校准超时 SLAdjustingControlManager 里的 adjustingTimeoutBlock
//        SLConnectManager.share().adjustingTimeoutBlock = {[weak self]  dev in
//            self?.present(SLAdjustingTimeoutViewController(), animated: false)
//        }
        
//        SLConnectManager.share().prepareAdjusting(withInitiative: self.isInitiative)
    }
    
    deinit {
//        SLConnectManager.share().adjustingSensitivityBigBlock = nil
//        SLConnectManager.share().adjustingTimeoutBlock = nil
//        NotificationCenter.default.removeObserver(self)
    }
    
    func prepareAdjusting(){
        
        self.adjustingView.prepareStartAdjustingControl { [weak self] _ in
            self?.status = .adjusting
            self?.upView()
            self?.adjustingView.startAdjustingControl()
        }
    }
    
    func adjustingResult(_ ret : Bool) {
        self.adjustingView.endAdjustingControl()
        self.status = ret ? .succeed : .fail
        self.upView()
    }

    func upView(){
        
        self.adjustingView.isUserInteractionEnabled = self.status == .adjusting
        
        self.adjustingSortView.isHidden = self.status == .start
        self.hintContentLabel.isHidden = true
        self.hintContentLabel.attributedText = nil
        self.hintContentLabel.text = nil
        self.openTouchView.isHidden = true
   
        self.statusBtn.isUserInteractionEnabled = true
        self.statusBtn.alpha = 1
        self.statusBtn.isHidden = false
        
        self.imageView.isHidden = true
        
        self.horImageView.stopAnimating()
        self.horImageView.isHidden = true
        
        self.verImageView.stopAnimating()
        self.verImageView.isHidden = true
        
        self.adjustingImageView.stopAnimating()
        self.adjustingImageView.isHidden = true
        
        if self.status == .start {
            
            self.imageView.isHidden = false
            self.imageView.image = UIImage.init(named: "adjusting_prepare_icon")
            self.hintLabel.text = NSLocalizedString("SLAdjustingStratHindString", comment: "")
            
            
            //  SLAdjustingManager 里的isOpenTouchControl()
//            if SLConnectManager.share().isOpenTouchControl() {
                self.openTouchView.isHidden = false
//            }
    
            self.statusBtn.setTitle(NSLocalizedString("SLAdjustingStratBtnString", comment: ""), for: .normal)
            
        } else if self.status == .horizontalOri {
            
            self.horImageView.isHidden = false
            self.horImageView.startAnimating()
            
            self.hintLabel.text = NSLocalizedString("SLAdjustingOriHindString", comment: "")
            self.hintContentLabel.isHidden = false
            self.hintContentLabel.text = NSLocalizedString("SLAdjustingHorizontalOriContentHindString", comment: "")
            self.statusBtn.isHidden = true
    
        } else if self.status == .verticalOri {
            
            self.verImageView.isHidden = false
            self.verImageView.startAnimating()
            
            self.hintLabel.text = NSLocalizedString("SLAdjustingOriHindString", comment: "")
            self.hintContentLabel.isHidden = false
            self.hintContentLabel.text = NSLocalizedString("SLAdjustingVerticalOriContentHindString", comment: "")
            self.statusBtn.isHidden = true
            
            self.adjustingSortView.currentIndex(1)
            
        } else if self.status == .prepareAdjusting {
            
            self.adjustingSortView.currentIndex(2)
            
            self.imageView.isHidden = false
            self.imageView.image = UIImage.init(named: "adjusting_adjustingPrepare_icon")
            self.hintLabel.text = NSLocalizedString("SLAdjustingPrepareTitleString", comment: "")
            self.hintContentLabel.isHidden = false
            
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.2
            style.alignment = .center
            
            self.hintContentLabel.attributedText = NSAttributedString(string: NSLocalizedString("SLAdjustingPrepareContentHindString", comment: ""), attributes: [NSAttributedString.Key.paragraphStyle: style])
            
                
            self.statusBtn.setTitle(NSLocalizedString("SLNextTitle", comment: ""), for: .normal)
            self.statusBtn.isHidden = false
            
        } else  if self.status == .adjusting {
            
            self.adjustingImageView.isHidden = false
            self.adjustingImageView.startAnimating()
            
            self.hintLabel.text = NSLocalizedString("SLAdjustingAdjustingHindString", comment: "")
            self.hintContentLabel.isHidden = false
            
            let style = NSMutableParagraphStyle()
            style.lineHeightMultiple = 1.2
            style.alignment = .center
            
            self.hintContentLabel.attributedText = NSAttributedString(string: NSLocalizedString("SLAdjustingAdjustingContentHindString", comment: ""), attributes: [NSAttributedString.Key.paragraphStyle: style])
            

            self.statusBtn.setTitle(NSLocalizedString("SLAdjustingBtnString", comment: ""), for: .normal)
            self.statusBtn.isUserInteractionEnabled = false
            self.statusBtn.alpha = 0.5
            
        } else if self.status == .succeed {
            
            self.imageView.isHidden = false
            self.imageView.image = UIImage.init(named: "adjusting_succeed_icon")
            self.hintLabel.text = NSLocalizedString("SLAdjustingsucceedHindString", comment: "")
            self.statusBtn.setTitle(NSLocalizedString("SLAdjustingsucceedBtnString", comment: ""), for: .normal)
            self.adjustingSortView.complete(result: true)
            
        } else {
            
            self.imageView.isHidden = false
            self.imageView.image = UIImage.init(named: "adjusting_fail_icon")
            self.hintLabel.text = NSLocalizedString("SLAdjustingFailHindString", comment: "")
            self.statusBtn.setTitle(NSLocalizedString("SLAdjustingFailBtnString", comment: ""), for: .normal)
            self.adjustingSortView.complete(result: false)
        }
    }
    
    @objc
    func btnPrssed(){
        if self.status == .start {
            self.adjustingView.startAdjustingOrientation()
            self.status = .horizontalOri
            self.upView()
        } else if self.status == .horizontalOri {
            self.status = .verticalOri
            self.upView()
        } else if self.status == .verticalOri {
            self.status = .prepareAdjusting
            self.upView()
        } else if self.status == .prepareAdjusting {
            self.status = .adjusting
            self.upView()
            self.prepareAdjusting()
        } else  if self.status == .adjusting {
            self.status = .fail
            self.upView()
        } else if self.status == .fail {
            self.status = .prepareAdjusting
            self.upView()
        } else if self.status == .succeed {
            self.dismiss(animated: true) { [weak self] in
                self?.dismissBlock?()
            }
            return
        }
    }
    
    @objc
    func disconnectDevice(){
        //校准中断开连接
//        let vc = SLAlertViewController(.error,
//                                       NSLocalizedString("SLAdjustingDisconnectDeviceString", comment: ""),
//                                       NSLocalizedString("SLAffirmTitle", comment: ""),
//                                       NSLocalizedString("SLAffirmTitle", comment: ""))
//        vc.finishBlock = {[weak self] _ in
//            self?.back()
//        }
//        self.present(vc, animated: false)
    }
    
    @objc
    func back(){
        //取消校准
        self.adjustingView.endAdjustingOrientation()
        self.adjustingView.endAdjustingControl()
        self.dismiss(animated: false) {}
    }
    
    override func viewDidLayoutSubviews() {
        
        if UIScreen.main.bounds.width < UIScreen.main.bounds.height {

            let distanceTop = UIDevice.safeDistanceTop()
            let distanceBottom = UIDevice.safeDistanceBottom()

            self.titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(distanceTop + 20)
            }

            self.imageView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(self.view.snp.centerY).offset(-40)
            }

            self.hintContentBackView.snp.remakeConstraints { make in
                make.left.equalTo(40)
                make.right.equalTo(-40)
                make.top.equalTo(self.imageView.snp.bottom).offset(15)
            }

            self.statusBtn.snp.remakeConstraints { make in
                make.width.equalTo(300)
                make.height.equalTo(48)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(-(distanceBottom + 80))
            }
            
            if self.status == .prepareAdjusting {
                self.statusBtn.isUserInteractionEnabled = true
                self.statusBtn.alpha = 1
            }

        } else  {
            
            let width = UIScreen.main.bounds.width > UIScreen.main.bounds.height ?  UIScreen.main.bounds.width :  UIScreen.main.bounds.height
            
            self.titleLabel.snp.remakeConstraints { make in
                make.width.equalTo(300)
                make.centerX.equalToSuperview()
                make.top.equalTo(40)
            }

            self.imageView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.centerX.equalTo(width/4.0)
            }

            self.hintContentBackView.snp.remakeConstraints { make in
                make.width.equalTo(300)
                make.centerY.equalToSuperview()
                make.centerX.equalTo((width/4.0) * 3)
            }

            self.statusBtn.snp.remakeConstraints { make in
                make.width.equalTo(300)
                make.height.equalTo(44)
                make.bottom.equalTo(-20)
                make.centerX.equalToSuperview()
            }
            
            if self.status == .prepareAdjusting {
                self.statusBtn.isUserInteractionEnabled = false
                self.statusBtn.alpha = 0.5
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}
