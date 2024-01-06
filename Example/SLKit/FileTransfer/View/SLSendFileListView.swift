////
////  SLSendFileListView.swift
////  FreeStyle
////
////  Created by shenjianfei on 2023/6/12.
////
//
//import UIKit
//
//private let cellkey = "sendFileCell"
//
//class SLSendFileListView: UIView {
//    
//    var editListBlock:(()->Void)?
//    
//    var deleteFilesBlock:((_ files: [SLFileModel]) -> Bool)?
//    var selectFileBlock:(()->Void)?
//    
//    private var isEdit = false
//    private lazy var files:[SLFileOperateModel] = []
//    
//    private var editView: UIView  = {
//        let view = UIView()
//        view.backgroundColor = .white
//        return view
//    }()
//
//    private var removeBtn: UIButton = {
//        let btn = UIButton()
//        btn.setBackgroundImage(UIImage.init(named: "notcan_remove_file_icon"), for: .normal)
//        btn.setBackgroundImage(UIImage.init(named: "can_remove_file_icon"), for: .selected)
//        btn.addTarget(self, action: #selector(removeList), for: .touchUpInside)
//        return btn
//    }()
//    
//    private var removeLabel: UILabel = {
//        let label = UILabel()
//        label.text = NSLocalizedString("SLFileRemoveString", comment: "")
//        label.textColor = UIColor.colorWithHex(hexStr: "#999999")
//        label.font = UIFont.font(12)
//        return label
//    }()
//    
//    private lazy var tabelView: UITableView = {
//        let tabelView = UITableView()
//        tabelView.delegate = self
//        tabelView.dataSource = self
//        tabelView.backgroundColor = .clear
//        tabelView.separatorStyle = .none
//        tabelView.contentInsetAdjustmentBehavior = .never
//        tabelView.register(SLFileListTableViewCell.self, forCellReuseIdentifier: cellkey)
//        return tabelView
//    }()
//    
//    func load(){
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
//        self.editView.addSubview(self.removeBtn)
//        self.removeBtn.snp.makeConstraints { make in
//            make.top.equalTo(30)
//            make.centerX.equalToSuperview()
//        }
//        
//        self.editView.addSubview(self.removeLabel)
//        self.removeLabel.snp.makeConstraints { make in
//            make.top.equalTo(self.removeBtn.snp.bottom).offset(10)
//            make.centerX.equalToSuperview()
//        }
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
//    func loadData(){
//        var models:[SLFileOperateModel] = []
//        _ = SLConnectManager.share().sendFiles().map({[weak self] file in
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
//        self.tabelView.reloadData()
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
//    func isSelectAll() -> Bool {
//        var selectCount =  0
//        _ = self.files.map({ file in
//            if file.isSelect {
//                selectCount = selectCount + 1
//            }
//            return file
//        })
//        return  self.files.count > 0 && selectCount == self.files.count
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
//        self.removeBtn.isSelected = selectCount > 0
//        self.removeBtn.isUserInteractionEnabled = self.removeBtn.isSelected
//        self.removeLabel.textColor = self.removeBtn.isSelected ? UIColor.colorWithHex(hexStr: "#333333") : UIColor.colorWithHex(hexStr: "#999999")
//    }
//    
//    @objc
//    func removeList() {
//        var list:[SLFileModel] = []
//        _ = self.files.map({ file in
//            if file.isSelect, let fileModel = file.fileModel {
//                list.append(fileModel)
//            }
//            return file
//        })
//        
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
//extension SLSendFileListView: UITableViewDelegate,UITableViewDataSource {
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.files.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: cellkey, for: indexPath) as! SLFileListTableViewCell
//        cell.selectFile(self.files[indexPath.row].isSelect)
//        guard let model = self.files[indexPath.row].fileModel else {
//            return cell
//        }
//        cell.edit(self.isEdit,model.fileType() == .folderFileType)
//        cell.showFile(model)
//        cell.editBlock = { [weak self] in
//            self?.editListBlock?()
//        }
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        if self.files.count == 0{
//            return tableView.bounds.height -  60
//        }
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let view =  UIView()
//        view.backgroundColor = .clear
//        
//        if self.files.count == 0{
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
//        return self.isEdit ? 200 : 0
//    }
//    
//    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        return UIView()
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if self.isEdit {
//            self.files[indexPath.row].isSelect = !self.files[indexPath.row].isSelect
//            self.tabelView.reloadData()
//            self.updateBtn()
//            self.selectFileBlock?()
//        } 
//    }
//}
