//
//  SLFunctionViewController.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/7/18.
//

import UIKit

class SCLFunctionViewController: SCLBaseViewController {
    
//    private lazy var titleLabel: UILabel = {
//        let label = UILabel(frame: CGRect.zero)
//        label.backgroundColor = .clear
//        label.font = UIFont.font(17,.medium)
//        label.textColor = UIColor.colorWithHex(hexStr: "191919")
//        label.text = NSLocalizedString("SLFunctionIntroduceTitle", comment: "")
//        label.textAlignment = .center
//        return label
//    }()
//    
//    private lazy var backBtn: UIButton = {
//        let btn = UIButton()
//        btn.setBackgroundImage(UIImage.init(named: "off_icon"), for: .normal)
//        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
//        return btn
//    }()
//    
//    private lazy var partingLine: UIView = {
//        let line = UIView()
//        line.backgroundColor = UIColor.colorWithHex(hexStr: "#000000", alpha: 0.1)
//        return line
//    }()
//    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    
    private lazy var screenImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "img_setting_function_screen")
        return imageView
    }()
    
    private lazy var screenTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.font = UIFont.font(15,.regular)
        label.textAlignment = .center
        label.text = NSLocalizedString("SLFunctionIntroduceScreenTitle", comment: "")
        label.numberOfLines = -1
        return label
    }()
    
    private lazy var screenContentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#666666")
        label.font = UIFont.font(12,.regular)
        label.text = NSLocalizedString("SLFunctionIntroduceScreenContent", comment: "")
        label.numberOfLines = -1
        return label
    }()
    
    
    private lazy var fileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "img_setting_function_file")
        return imageView
    }()
    
    private lazy var fileTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.font = UIFont.font(15,.regular)
        label.textAlignment = .center
        label.text = NSLocalizedString("SLFunctionIntroduceFileTransferTitle", comment: "")
        label.numberOfLines = -1
        return label
    }()
    
    private lazy var fileContentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#666666")
        label.font = UIFont.font(12,.regular)
        label.text = NSLocalizedString("SLFunctionIntroduceFileTransferContent", comment: "")
        label.numberOfLines = -1
        return label
    }()
    
    
    private lazy var downloadUrlLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.colorWithHex(hexStr: "#666666")
        label.font = UIFont.font(12,.regular)
        label.text = "\(NSLocalizedString("SLFunctionIntroduceDownloadUrlString", comment: ""))\(NSLocalizedString("SLPCAPPDownloadUrl", comment: ""))"
        label.numberOfLines = -1
        label.textAlignment = .center
        return label
    }()
    
    
    override func loadView() {
        super.loadView()
        
        navigationItem.title = NSLocalizedString("SLFunctionIntroduceTitle", comment: "")
        
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
        
        self.view.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.view.snp.top)
            make.bottom.left.right.equalTo(0)
        }
        
        self.scrollView.addSubview(self.screenImageView)
        self.screenImageView.snp.makeConstraints { make in
            make.centerX.equalTo(screenWidth/2.0)
            make.top.equalTo(20)
        }

        self.scrollView.addSubview(self.screenTitleLabel)
        self.screenTitleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(screenWidth/2.0)
            make.top.equalTo(self.screenImageView.snp.bottom).offset(15)
            make.left.equalTo(30)
            make.width.equalTo(screenWidth-60)
        }

        self.scrollView.addSubview(self.screenContentLabel)
        self.screenContentLabel.snp.makeConstraints { make in
            make.centerX.equalTo(screenWidth/2.0)
            make.top.equalTo(self.screenTitleLabel.snp.bottom).offset(10)
            make.left.equalTo(30)
            make.width.equalTo(screenWidth-60)
        }

        self.scrollView.addSubview(self.fileImageView)
        self.fileImageView.snp.makeConstraints { make in
            make.centerX.equalTo(screenWidth/2.0)
            make.top.equalTo(self.screenContentLabel.snp.bottom).offset(30)
        }

        self.scrollView.addSubview(self.fileTitleLabel)
        self.fileTitleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(screenWidth/2.0)
            make.top.equalTo(self.fileImageView.snp.bottom)
            make.left.equalTo(20)
            make.width.equalTo(screenWidth-40)
        }
        
        self.scrollView.addSubview(self.fileContentLabel)
        self.fileContentLabel.snp.makeConstraints { make in
            make.centerX.equalTo(screenWidth/2.0)
            make.top.equalTo(self.fileTitleLabel.snp.bottom).offset(10)
            make.left.equalTo(20)
            make.width.equalTo(screenWidth-40)
        }
        
        self.scrollView.addSubview(self.downloadUrlLabel)
        self.downloadUrlLabel.snp.makeConstraints { make in
            make.centerX.equalTo(screenWidth/2.0)
            make.top.equalTo(self.fileContentLabel.snp.bottom).offset(70)
            make.left.equalTo(20)
            make.width.equalTo(screenWidth-40)
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor =  UIColor.colorWithHex(hexStr: "#f7f7f7", alpha: 1)
    }
    
    @objc
    func back(){
        self.dismiss(animated: true)
    }

    override func viewDidLayoutSubviews() {
        self.scrollView.contentSize = CGSize(width: screenWidth, height: self.downloadUrlLabel.frame.maxY)
    }
}
