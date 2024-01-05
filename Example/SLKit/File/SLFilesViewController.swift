//
//  SLFilesViewController.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/6/11.
//

import UIKit

private let selectColor = UIColor.colorWithHex(hexStr: "#586CFF")
private let notselectColor = UIColor.colorWithHex(hexStr: "#666666")


class SLFilesViewController: SLBaseViewController {
    
    private lazy var isEdit = false
    private var device: SLDeviceModel?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = .clear
        label.font = UIFont.font(17,.medium)
        label.textColor = UIColor.colorWithHex(hexStr: "#191919")
        label.text = NSLocalizedString("SLFileTitleString", comment: "")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage.init(named: "back_icon"), for: .normal)
        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.font(15,.medium)
        return btn
    }()
    
    private lazy var moreBtn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage.init(named: "file_edit_icon"), for: .normal)
        btn.setBackgroundImage(UIImage.init(named: "off_icon"), for: .selected)
        btn.addTarget(self, action: #selector(edit), for: .touchUpInside)
        return btn
    }()

    private lazy var partingLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.colorWithHex(hexStr: "#000000", alpha: 0.1)
        return line
    }()
    
    private lazy var receiveFileBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLFileReceiveTitleString", comment: ""), for: .normal)
        btn.setTitleColor(selectColor, for: .normal)
        btn.titleLabel?.font = UIFont.font(15,.medium)
        btn.addTarget(self, action: #selector(receiveFile), for: .touchUpInside)
        return btn
    }()
    
    private lazy var sendFileBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("SLFileSendTitleString", comment: ""), for: .normal)
        btn.setTitleColor(notselectColor, for: .normal)
        btn.titleLabel?.font = UIFont.font(15,.medium)
        btn.addTarget(self, action: #selector(sendFile), for: .touchUpInside)
        return btn
    }()
    
    private lazy var tagView: UIView = {
        let view = UIView()
        view.backgroundColor = selectColor
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 1
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        return scrollView
    }()
    
    private lazy var receiveFileListView: SLReceiveFileListView = {
        let view = SLReceiveFileListView()
        view.backgroundColor = UIColor.colorWithHex(hexStr: "#f7f7f7", alpha: 1)
        view.load()
        return view
    }()
    
    private lazy var sendFileListView: SLSendFileListView = {
        let view = SLSendFileListView()
        view.backgroundColor = UIColor.colorWithHex(hexStr: "#f7f7f7", alpha: 1)
        view.load()
        return view
    }()
    
    
    private var openedFile: SLFileModel?
    
    init(device: SLDeviceModel? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.device = device
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        let distanceTop = UIDevice.safeDistanceTop()
        
        self.view.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(distanceTop + 20)
        }
        
        self.view.addSubview(self.backBtn)
        self.backBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel.snp.centerY)
            make.left.equalTo(20)
        }
        
        self.view.addSubview(self.moreBtn)
        self.moreBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel.snp.centerY)
            make.right.equalTo(-20)
        }
        
        self.view.addSubview(self.partingLine)
        self.partingLine.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(20)
            make.height.equalTo(1)
            make.left.right.equalTo(0)
        }
        
        self.view.addSubview(self.receiveFileBtn)
        self.receiveFileBtn.snp.makeConstraints { make in
            make.top.equalTo(self.partingLine.snp.bottom).offset(20)
            make.centerX.equalTo(screenWidth/4.0)
        }
        
        self.view.addSubview(self.sendFileBtn)
        self.sendFileBtn.snp.makeConstraints { make in
            make.top.equalTo(self.partingLine.snp.bottom).offset(20)
            make.centerX.equalTo(screenWidth/4.0*3)
        }
        
        self.view.addSubview(self.tagView)
        self.tagView.snp.makeConstraints { make in
            make.top.equalTo(self.receiveFileBtn.snp.bottom)
            make.centerX.equalTo(self.receiveFileBtn.snp.centerX)
            make.width.equalTo(60)
            make.height.equalTo(2)
        }
        
        self.view.addSubview(self.scrollView)
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.tagView.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        self.scrollView.addSubview(self.receiveFileListView)
        self.receiveFileListView.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.equalTo(screenWidth)
            make.height.equalTo(screenHeight - 130)
        }
        
        self.scrollView.addSubview(self.sendFileListView)
        self.sendFileListView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(self.receiveFileListView.snp.right)
            make.width.equalTo(screenWidth)
            make.right.equalToSuperview()
            make.height.equalTo(screenHeight - 130)
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.colorWithHex(hexStr: "#f7f7f7", alpha: 1)
        
        self.receiveFileListView.sendFilesBlock = { [weak self] files in
            self?.endEdit()
            if files.count == 0 {
                return false
            }
            SLAnalyticsManager.share().sendFile(with: .freestyleSendFileEdit)
            if let device = self?.device {
                _ = files.map({ file in
                    SLConnectManager.share().prepareSendFileModel(with:file)
                    return true
                })
                SLConnectManager.share().sendFile(withDevice: device, files: files) { _, _ in  }
            } else {
                let vc = SLSendFileSelectDeviceViewController(files, checkFiles: false)
                self?.present(vc, animated: true)
            }
            return true
        }
        
        self.receiveFileListView.deleteFilesBlock = {[weak self] files in
            self?.endEdit()
            if files.count == 0 {
                return false
            }
            SLConnectManager.share().deleteReceiveFiles(files)
            let appDeleget = UIApplication.shared.delegate as? AppDelegate
            appDeleget?.toast(NSLocalizedString("SLFileDeleteSuccessString", comment: ""))
            return true
        }
        
        self.receiveFileListView.selectFileBlock = { [weak self] in
            self?.upDataBackBtn()
        }
        
        self.receiveFileListView.editListBlock = { [weak self] in
            if self?.isEdit ?? false {
                return
            }
            self?.edit()
        }
            
        self.sendFileListView.deleteFilesBlock = { [weak self] files in
            self?.endEdit()
            if files.count == 0 {
                return false
            }
            SLConnectManager.share().deleteSendFiles(files)
            let appDeleget = UIApplication.shared.delegate as? AppDelegate
            appDeleget?.toast(NSLocalizedString("SLFileRemoveSuccessString", comment: ""))
            return true
        }
        
        self.sendFileListView.selectFileBlock = { [weak self] in
            self?.upDataBackBtn()
        }
         
        self.sendFileListView.editListBlock = { [weak self] in
            if self?.isEdit ?? false {
                return
            }
            self?.edit()
        }
        
        self.receiveFileListView.loadData()
        self.receiveFileListView.upDateFileTransfer()
        self.sendFileListView.loadData()
    }
    
    func updateSendList(){
        self.sendFileListView.upDataList()
    }
    
    func updateReceiveList(){
        self.receiveFileListView.upDataList()
    }
    
    func updateRreceiveFileTransferProgress(_ device: SLDeviceModel,_ taskId: String,_ progress: Float){
        self.receiveFileListView.updateProgress(taskId: taskId, pro: progress)
    }
    
    func upDateFileTransferList(){
        self.receiveFileListView.upDateFileTransfer()
    }

    @objc
    func back(){
        if self.isEdit {
            if self.scrollView.contentOffset.x == 0 {
                self.receiveFileListView.selectAll(!self.receiveFileListView.isSelectAll())
                self.upDataBackBtn()
            } else {
                self.sendFileListView.selectAll(!self.sendFileListView.isSelectAll())
                self.upDataBackBtn()
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc
    func edit(){
        self.isEdit = !self.isEdit
        self.moreBtn.isSelected = self.isEdit
        self.receiveFileListView.edit(self.isEdit)
        self.sendFileListView.edit(self.isEdit)
        self.upDataBackBtn()
    }
    
    @objc
    func receiveFile(){
        self.endEdit()
        self.scrollView.setContentOffset(CGPoint.init(x: 0, y: 0), animated: true)
    }
    
    @objc
    func sendFile(){
        self.endEdit()
        self.scrollView.setContentOffset(CGPoint.init(x: screenWidth, y: 0), animated: true)
    }
    
    func endEdit(){
        self.isEdit = false
        self.moreBtn.isSelected = self.isEdit
        self.upDataBackBtn()
    }
    
    func upDataBackBtn(){
        if self.isEdit {
            self.backBtn.setBackgroundImage(nil, for: .normal)
            let isAll = self.scrollView.contentOffset.x == 0 ? self.receiveFileListView.isSelectAll() : self.sendFileListView.isSelectAll()
            self.backBtn.setTitle(isAll ?  NSLocalizedString("SLFileCancelSelectAllString", comment: "") : NSLocalizedString("SLFileSelectAllString", comment: ""), for: .normal)
            self.backBtn.setTitleColor(UIColor.colorWithHex(hexStr: "#586CFF"), for: .normal)
        } else {
            self.backBtn.setBackgroundImage(UIImage.init(named: "back_icon"), for: .normal)
            self.backBtn.setTitle(nil, for: .normal)
            self.backBtn.setTitleColor(UIColor.clear, for: .normal)
        }
    }
}

extension SLFilesViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.tagView.snp.remakeConstraints { make in
            make.top.equalTo(self.receiveFileBtn.snp.bottom)
            make.centerX.equalTo(screenWidth/4.0+scrollView.contentOffset.x/2.0)
            make.width.equalTo(60)
            make.height.equalTo(2)
        }
        self.receiveFileBtn.setTitleColor(scrollView.contentOffset.x == 0 ? selectColor : notselectColor, for: .normal)
        self.sendFileBtn.setTitleColor(scrollView.contentOffset.x == screenWidth ? selectColor : notselectColor, for: .normal)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.isEdit = false
        self.moreBtn.isSelected = self.isEdit
        self.receiveFileListView.edit(self.isEdit)
        self.sendFileListView.edit(self.isEdit)
        self.upDataBackBtn()
    }
}

