//
//  SLAdjustingViewController.swift
//  OMNIEnjoy
//
//  Created by shenjianfei on 2023/11/15.
//

import UIKit
import SLKit

fileprivate enum SLAdjustingStatusType {
    case start
    case horizontalOri
    case verticalOri
    case prepareAdjusting
    case adjusting
    case succeed
    case fail
}

class SLAdjustingViewController: SCLBaseViewController {
    
    private lazy var status: SLAdjustingStatusType = .start
    var dismissBlock:(()->Void)?
    private var isInitiative = false
    private var device: SLDevice?
    private let manager = SLAdjustingControlManager()
    
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
    
    init(initiative: Bool, device: SLDevice) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.isInitiative = initiative
        self.device = device
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
        
        self.hintContentBackView.addSubview(self.adjustingSortView)
        self.adjustingSortView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.hintContentLabel.snp.bottom).offset(40)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        self.view.addSubview(self.openTouchView)
        self.openTouchView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.top.equalTo(self.imageView.snp.bottom).offset(75)
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
        
        // TODO: 设置断开连接的回调
//        NotificationCenter.default.addObserver(self, selector: #selector(disconnectDevice), name:Notification.Name(K_Notice_Disonnect), object: nil)
        
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
        
        self.adjustingView.adjustingPointUpdated = { [weak self] point in
            self?.manager.adjusting(point)
        }
        
        manager.adjustingSensitivityBigBlock = {[weak self] in
            self?.present(SLAdjustingSensitivityBigHintViewController(), animated: false)
        }
        
        manager.adjustingTimeoutBlock = {[weak self] in
            self?.present(SLAdjustingTimeoutViewController(), animated: false)
        }
        
        manager.adjustingMoveBlock = { [weak self] (step, x, y) in
            guard let socket = self?.device?.localClient else {
                SLLog.debug("同步校准点时已断开连接")
                self?.status = .fail
                return
            }
            SLSocketManager.shared.send(
                SCLSyncMovePointReq(step: step, x: x, y: y),
                from: socket,
                for: SCLSyncMovePointResp.self) { _ in }
        }
        
        manager.adjustingResultBlock = { [weak self] (result, adjustingData) in
            if let adjustingData, result {
                // MARK: 校准成功，保存校准数据到本地，并上传
                let saveAdjustingData = SCLUtil.setCalibrationData(adjustingData)
                SLLog.debug("保存校准数据\(saveAdjustingData ? "成功" : "失败")")
                guard saveAdjustingData else {
                    self?.status = .fail
                    return
                }
                guard let socket = self?.device?.localClient else {
                    SLLog.debug("上传校准数据时已断开连接")
                    self?.status = .fail
                    return
                }
                SLSocketManager.shared.send(
                    SCLSocketRequest(content: SCLUploadCalibrationDataReq(data: adjustingData)),
                    from: socket,
                    for: SCLSocketResponse<SCLUploadCalibrationDataResp>.self)
                { [weak self] result in
                    var error: String?
                    switch result {
                    case .success(let resp):
                        error = resp.content?.succ == 1 ? nil : "upload adjusting data failed"
                    case .failure(let e):
                        error = e.localizedDescription
                    }
                    DispatchQueue.main.async {
                        if let error {
                            self?.toast(error)
                        }
                    }
                }
                self?.status = .succeed
            } else {
                self?.status = .fail
            }
            self?.upView()
        }
//        manager.prepareAdjusting(withInitiative: self.isInitiative)
    }
    
    deinit {
        manager.adjustingSensitivityBigBlock = nil
        manager.adjustingTimeoutBlock = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func prepareAdjusting(){
        guard let socket = device?.localClient else {
            // TODO: 已断开连接
            return
        }
        // MARK: 发送cmd10 state 1表示开始校准 2表示取消校准
        SLSocketManager.shared.send(
            SCLSyncCalibrationStateReq(state: 3),
            from: socket,
            for: SCLSyncCalibrationStateResp.self)
        { [weak self] result in
            var error: String?
            switch result {
            case .success(let resp):
                error = resp.state == 3 ? nil : "sync adjustting state failed"
            case .failure(let e):
                error = e.localizedDescription
            }
            DispatchQueue.main.async {
                if let error {
                    SLLog.debug("开启校准失败：\(error)")
                    self?.toast(error)
                } else {
                    SLLog.debug("开启校准成功")
                    self?.status = .adjusting
                    self?.upView()
                    self?.adjustingView.startAdjustingControl()
                    self?.manager.startAdjustingControl()
                }
            }
        }
//        self.adjustingView.prepareStartAdjustingControl { [weak self] _  in
//            self?.status = .adjusting
//            self?.upView()
//            self?.adjustingView.startAdjustingControl()
//        }
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
        self.openTouchView.isUserInteractionEnabled = false
   
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
            
            if manager.isOpenTouchControl() {
                self.openTouchView.isHidden = false
                self.openTouchView.isUserInteractionEnabled = true
            }
    
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
//            manager.startAdjustingControl()
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
        let vc = SCLAlertViewController(.error,
                                       NSLocalizedString("SLAdjustingDisconnectDeviceString", comment: ""),
                                       NSLocalizedString("SLAffirmTitle", comment: ""),
                                       NSLocalizedString("SLAffirmTitle", comment: ""))
        vc.finishBlock = {[weak self] _ in
            self?.back()
        }
        self.present(vc, animated: false)
    }
    
    @objc
    func back(){
        manager.endAdjustingControl()
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
            
            self.view.addSubview(self.openTouchView)
            self.openTouchView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(300)
                make.top.equalTo(self.imageView.snp.bottom).offset(75)
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
            
            self.openTouchView.snp.remakeConstraints { make in
                make.centerX.equalTo((width/4.0) * 3)
                make.width.equalTo(300)
                make.bottom.equalTo(self.statusBtn.snp.top).offset(-20)
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
