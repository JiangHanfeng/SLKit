////
////  SLReceiveFileListView.swift
////  FreeStyle
////
////  Created by shenjianfei on 2023/6/12.
////
//
//import UIKit
//import QuickLook
//
//private let cellkey = "ReceiveFileCell"
//private let cellkey1 = "ReceivingFileCell"
//
//class SLReceiveFileListView: UIView {
//    
//    var editListBlock:(()->Void)?
//    var sendFilesBlock:((_ files: [SLFileModel]) -> Bool)?
//    var deleteFilesBlock:((_ files: [SLFileModel]) -> Bool)?
//    var selectFileBlock:(()->Void)?
//    
//    private var fileTransfers: [SLFileTransferModel] = []
//    private var files:[SLFileOperateModel] = []
//    private var isEdit = false
//    private var openFile:SLFileModel?
//    
//    private var editView: UIView  = {
//        let view = UIView()
//        view.backgroundColor = .white
//        return view
//    }()
//    
//    private lazy var tabelView: UITableView = {
//        let tabelView = UITableView()
//        tabelView.delegate = self
//        tabelView.dataSource = self
//        tabelView.backgroundColor = .clear
//        tabelView.separatorStyle = .none
//        tabelView.register(SLFileListTableViewCell.self, forCellReuseIdentifier: cellkey)
//        tabelView.register(SLReceivingFileTableViewCell.self, forCellReuseIdentifier: cellkey1)
//        return tabelView
//    }()
//
//    private lazy var sendBtn: UIButton = {
//        let btn = UIButton()
//        btn.setBackgroundImage(UIImage.init(named: "notcan_send_file_icon"), for: .normal)
//        btn.setBackgroundImage(UIImage.init(named: "can_send_file_icon"), for: .selected)
//        btn.addTarget(self, action: #selector(sendFile), for: .touchUpInside)
//        return btn
//    }()
//    
//    private lazy var sendLabel: UILabel = {
//        let label = UILabel()
//        label.text = NSLocalizedString("SLFileSendString", comment: "")
//        label.textColor = UIColor.colorWithHex(hexStr: "#999999")
//        label.font = UIFont.font(12)
//        return label
//    }()
//    
//    private lazy var deleteBtn: UIButton = {
//        let btn = UIButton()
//        btn.setBackgroundImage(UIImage.init(named: "notcan_delete_file_icon"), for: .normal)
//        btn.setBackgroundImage(UIImage.init(named: "can_delete_file_icon"), for: .selected)
//        btn.addTarget(self, action: #selector(deleteFile), for: .touchUpInside)
//        return btn
//    }()
//    
//    private lazy var deleteLabel: UILabel = {
//        let label = UILabel()
//        label.text = NSLocalizedString("SLFileDeleteString", comment: "")
//        label.textColor = UIColor.colorWithHex(hexStr: "#999999")
//        label.font = UIFont.font(12)
//        return label
//    }()
//        
//    func load(){
//        
//        self.addSubview(self.tabelView)
//        self.tabelView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        
//        self.addSubview(self.editView)
//        self.editView.snp.makeConstraints { make in
//            make.height.equalTo(200)
//            make.top.equalTo(self.snp.bottom)
//            make.width.equalTo(screenWidth)
//            make.centerX.equalToSuperview()
//        }
//        
//        self.editView.addSubview(self.sendBtn)
//        self.sendBtn.snp.makeConstraints { make in
//            make.top.equalTo(30)
//            make.centerX.equalTo(screenWidth/4.0)
//        }
//        
//        self.editView.addSubview(self.sendLabel)
//        self.sendLabel.snp.makeConstraints { make in
//            make.top.equalTo(self.sendBtn.snp.bottom).offset(10)
//            make.centerX.equalTo(screenWidth/4.0)
//        }
//        
//        self.editView.addSubview(self.deleteBtn)
//        self.deleteBtn.snp.makeConstraints { make in
//            make.top.equalTo(30)
//            make.centerX.equalTo(screenWidth/4.0 * 3)
//        }
//        
//        self.editView.addSubview(self.deleteLabel)
//        self.deleteLabel.snp.makeConstraints { make in
//            make.top.equalTo(self.sendBtn.snp.bottom).offset(10)
//            make.centerX.equalTo(screenWidth/4.0 * 3)
//        }
//    }
//    
//    func upDateFileTransfer(){
//        self.fileTransfers = SLConnectManager.share().receiveFileTransfers()
//        self.tabelView.reloadData()
//    }
//    
//    func loadData(){
//        var models:[SLFileOperateModel] = []
//        _ = SLConnectManager.share().receiveFiles().map({[weak self] file in
//            var isAdd = true
//            for model in (self?.files ?? []) {
//                if model.fileModel?.path == file.path &&
//                    model.fileModel?.extensionName == file.extensionName &&
//                    model.fileModel?.name == file.name {
//                    models.append(SLFileOperateModel.model(file))
//                    isAdd = false
//                }
//            }
//            if isAdd {
//                models.append(SLFileOperateModel.model(file))
//            }
//        })
//        self.files = models
//        self.tabelView.reloadData()
//    }
//    
//    func upDataList(){
//        self.loadData()
//    }
//    
//    func edit(_ isEdit: Bool) {
//        self.isEdit = isEdit
//        if isEdit == false {
//            for item in self.files {
//                item.isSelect = false
//            }
//        }
//        self.tabelView.reloadData()
//        UIView.animate(withDuration: 0.5) {
//            self.editView.snp.remakeConstraints { make in
//                make.height.equalTo(200)
//                make.width.equalTo(screenWidth)
//                make.centerX.equalToSuperview()
//                if isEdit {
//                    make.bottom.equalToSuperview()
//                } else {
//                    make.top.equalTo(self.snp.bottom)
//                }
//            }
//        }
//    }
//    
//    func selectAll(_ select: Bool){
//        self.files = self.files.map({ file in
//            file.isSelect = select
//            return file
//        })
//        self.tabelView.reloadData()
//        self.updateBtn()
//    }
//
//    func updateProgress(taskId:String, pro:Float) {
//        _ = self.fileTransfers.map { model in
//            if model.taskId == taskId {
//                model.currentProgress = pro
//            }
//        }
//        self.tabelView.reloadData()
//    }
//    
//    func isSelectAll() -> Bool {
//        var selectCount =  0
//        _ = self.files.map({ file in
//            if file.isSelect {
//                selectCount = selectCount + 1
//            }
//            return true
//        })
//        return self.files.count > 0 && selectCount == self.files.count
//    }
//    
//    func updateBtn(){
//        var selectCount =  0
//        _ = self.files.map({ file in
//            if file.isSelect {
//                selectCount = selectCount + 1
//            }
//            return file
//        })
//        self.sendBtn.isSelected = selectCount > 0
//        self.sendBtn.isUserInteractionEnabled = self.sendBtn.isSelected
//        self.sendLabel.textColor = self.sendBtn.isSelected ? UIColor.colorWithHex(hexStr: "#333333") : UIColor.colorWithHex(hexStr: "#999999")
//        
//        self.deleteBtn.isSelected = selectCount > 0
//        self.deleteBtn.isUserInteractionEnabled = self.deleteBtn.isSelected
//        self.deleteLabel.textColor = self.deleteBtn.isSelected ? UIColor.colorWithHex(hexStr: "#333333") : UIColor.colorWithHex(hexStr: "#999999")
//    }
//    
//    @objc
//    func sendFile(){
//        var list: [SLFileModel] = []
//        _ = self.files.map({ file in
//            if file.isSelect,
//                let model = file.fileModel {
//                list.append(model)
//            }
//            return true
//        })
//        _ = self.sendFilesBlock?(list)
//        self.edit(false)
//    }
//    
//    @objc
//    func deleteFile(){
//        var list:[SLFileModel] = []
//        _ = self.files.map({ file in
//            if file.isSelect, let fileModel = file.fileModel {
//                list.append(fileModel)
//            }
//            return file
//        })
//        if self.deleteFilesBlock?(list) ?? false {
//            self.files.removeAll { model in
//                for item in list {
//                    if item.path == model.fileModel?.path &&
//                        item.extensionName == model.fileModel?.extensionName &&
//                        item.name == model.fileModel?.name {
//                        return true
//                    }
//                }
//                return false
//            }
//            self.edit(false)
//        } else {
//            self.edit(false)
//        }
//    }
//}
//
//extension SLReceiveFileListView: UITableViewDelegate,UITableViewDataSource {
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        var  count: Int = 0
//        if (self.fileTransfers.count > 0){
//            count = count + 1
//        }
//        if (self.files.count > 0){
//            count = count + 1
//        }
//        return count == 0 ? 1 : count
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if section == 0 {
//            if self.fileTransfers.count > 0{
//                return self.fileTransfers.count
//            } else {
//                return self.files.count
//            }
//        } else {
//            return self.files.count
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        if self.fileTransfers.count > 0, indexPath.section == 0{
//            let cell = tableView.dequeueReusableCell(withIdentifier: cellkey1, for: indexPath) as! SLReceivingFileTableViewCell
//            cell.showFile(self.fileTransfers[indexPath.row])
//            cell.setProgress(self.fileTransfers[indexPath.row].currentProgress)
//            cell.setCancelBlock { [weak self] in
//                SLConnectManager.share().cancelFiles(withTaskId: self?.fileTransfers[indexPath.row].taskId ?? "")
//                self?.upDateFileTransfer()
//            }
//            return cell
//        } else {
//            let cell = tableView.dequeueReusableCell(withIdentifier: cellkey, for: indexPath) as! SLFileListTableViewCell
//            cell.selectFile(self.files[indexPath.row].isSelect)
//            guard let model = self.files[indexPath.row].fileModel else {
//                return cell
//            }
//            cell.edit(self.isEdit,model.fileType() == .folderFileType)
//            cell.showFile(model)
//            cell.editBlock = { [weak self] in
//                self?.editListBlock?()
//            }
//            return cell
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        if self.files.count == 0 , self.fileTransfers.count == 0{
//            return tableView.bounds.height -  60
//        }
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let view =  UIView()
//        view.backgroundColor = .clear
//        if self.files.count == 0 , self.fileTransfers.count == 0{
//            
//            let imageView = UIImageView()
//            imageView.image = UIImage.init(named: "not_file_img")
//            view.addSubview(imageView)
//            imageView.snp.makeConstraints { make in
//                make.centerX.equalToSuperview()
//                make.bottom.equalTo(view.snp.centerY).offset(-60)
//            }
//            
//            let label = UILabel()
//            label.textColor = UIColor.colorWithHex(hexStr: "#666666")
//            label.font = UIFont.font(14)
//            label.text = NSLocalizedString("SLFileEmptyFilesString", comment: "")
//            view.addSubview(label)
//            label.snp.makeConstraints { make in
//                make.centerX.equalToSuperview()
//                make.top.equalTo(imageView.snp.bottom)
//            }
//            
//        }
//        return view
//    }
//    
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        if section > 0 {
//            return self.isEdit ? 200 : 0
//        }
//        return 0
//    }
//    
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        return UIView()
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if self.fileTransfers.count > 0, indexPath.section == 0{
//            
//        } else {
//            if self.isEdit {
//                self.files[indexPath.row].isSelect = !self.files[indexPath.row].isSelect
//                self.tabelView.reloadData()
//                self.updateBtn()
//                self.selectFileBlock?()
//            } else {
//                let fileModel = self.files[indexPath.row].fileModel
//                guard let status = fileModel?.fileType(),
//                      status != .unknownFileType,
//                      status != .folderFileType,
//                      status != .zipFileType else {
//                    return
//                }
//                self.openFile = fileModel
//                let previewController = QLPreviewController()
//                previewController.dataSource = self
//                previewController.delegate = self
//                UIViewController.getCurrentViewController()?.present(previewController, animated: true, completion: nil)
//            }
//        }
//    }
//}
//
//extension SLReceiveFileListView: QLPreviewControllerDataSource,QLPreviewControllerDelegate {
//    
//    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
//            return 1
//    }
//    
//    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
//        let path = SLConnectManager.share().localFilePath(self.openFile!)
//        return URL.init(fileURLWithPath: path) as QLPreviewItem
//    }
//}
