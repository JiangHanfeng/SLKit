//
//  SCLFileRecordViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/25.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import RxCocoa
import QuickLook

enum SCLFileType: String {
    case audio, compressed, excel, folder, image, pdf, ppt, text, video, word, unknown
}

enum SCLFileTransferType {
    case receive, send
}

struct SCLFileRecord {
    let name: String
    let fullName: String
    let extensionName: String
    let path: String
    let fullPath: String
    let time: String
    let fileType: SCLFileType
    let transferType: SCLFileTransferType
}

struct SCLFileRecordCellModel {
    let record: SCLFileRecord
    var isSelected = false
}

class SCLFileRecordViewController: SCLBaseViewController {
    
    private var transferType: SCLFileTransferType
    private var onEnterEditing: (() -> Void)?
    private var onSelectedRecordsChanged: ((_ selectedRecords: [SCLFileRecordCellModel]) -> Void)?
    private var onCancelTransfer: ((_ taskId: String) -> Void)?
    
    private let tableView = UITableView()
    private var transferrs: [SCLTransferringModel] = []
    private var records: [SCLFileRecordCellModel] = []
    private var previewFile: SCLFileRecord?
//    private let dataSource = BehaviorRelay(value: [SCLFileRecordCellModel]())
    
    
    init(
        transferType: SCLFileTransferType,
        enterEditing: @escaping (() -> Void),
        onSelectedRecordsChanged: @escaping ((_ selectedRecords: [SCLFileRecordCellModel]) -> Void),
        onCancelTransfer: @escaping ((_ taskId: String) -> Void)
    ) {
        self.transferType = transferType
        self.onEnterEditing = enterEditing
        self.onSelectedRecordsChanged = onSelectedRecordsChanged
        self.onCancelTransfer = onCancelTransfer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.transferType = .receive
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 247/255.0, green: 247/255.0, blue: 247/255.0, alpha: 1)
        tableView.backgroundColor = UIColor(red: 247/255.0, green: 247/255.0, blue: 247/255.0, alpha: 1)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }
        
        tableView.estimatedRowHeight = 76
        tableView.rowHeight = 76
        tableView.allowsSelectionDuringEditing = true
        tableView.register(UINib(nibName: String(describing: SCLTransferringCell.self), bundle: Bundle.main), forCellReuseIdentifier: SCLTransferringCell.reuseIdentifier)
        tableView.register(UINib(nibName: String(describing: SCLFileRecordCell.self), bundle: Bundle.main), forCellReuseIdentifier: SCLFileRecordCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        
//        dataSource.bind(to: tableView.rx.items(cellIdentifier: SCLFileRecordCell.reuseIdentifier, cellType: SCLFileRecordCell.self)) { [unowned self] (row, model, cell) in
//            cell.setName(model.record.name)
//            cell.setTime(model.record.time)
//            cell.setImage(UIImage(named: "icon_file_\(model.record.fileType.rawValue)"))
//            cell.isSelected = model.isSelected
//            if cell.showSelectionView != tableView.isEditing {
//                cell.setEditing(tableView.isEditing, animated: true)
//            }
//        }.disposed(by: disposeBag)
//        tableView.rx.itemSelected.subscribe { [weak self] indexPath in
//            guard self?.tableView.isEditing == true else {
//                return
//            }
//            if var records = self?.records {
//                let isSelected = records[indexPath.row].isSelected
//                records[indexPath.row].isSelected = !isSelected
//                self?.records = records
//                self?.dataSource.accept(records)
//                if let selectedRecords = self?.records.filter({ $0.isSelected }) {
//                    self?.onSelectedRecordsChanged?(selectedRecords)
//                }
//            }
//        }.disposed(by: disposeBag)
        
        let longPress = UILongPressGestureRecognizer()
        tableView.addGestureRecognizer(longPress)
        longPress.rx.event.bind { [unowned self] _ in
            self.tableView.setEditing(true, animated: true)
            self.onEnterEditing?()
        }.disposed(by: disposeBag)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func enterEdit() {
        tableView.setEditing(true, animated: true)
    }
    
    func cancelEdit() {
        tableView.setEditing(false, animated: true)
        DispatchQueue.global().async { [weak self] in
            if let records = self?.records.map({ item in
                var newItem = item
                newItem.isSelected = false
                return newItem
            }) {
                DispatchQueue.main.async {
                    self?.records = records
//                    self?.dataSource.accept(records)
                    self?.onSelectedRecordsChanged?([])
                }
            }
        }
    }
    
    func selectAll() {
        DispatchQueue.global().async { [weak self] in
            if let records = self?.records.map { item in
                var newItem = item
                newItem.isSelected = true
                return newItem
            } {
                self?.onSelectedRecordsChanged?(records.filter({ $0.isSelected }))
                DispatchQueue.main.async { [weak self] in
                    self?.records = records
                    self?.tableView.reloadData()
                }
            }
        }
//        dataSource.accept(records)
    }
    
    func updateFileRecords(_ array: [SCLFileRecordCellModel]) {
        self.records = array
        DispatchQueue.main.async {
            self.tableView.reloadData()
//            self.dataSource.accept(models)
        }
    }
    
    func updateTransferringFiles(_ array: [SCLTransferringModel]) {
        self.transferrs = array
        DispatchQueue.main.async {
            self.tableView.reloadData()
//            self.dataSource.accept(models)
        }
    }
}

extension SCLFileRecordViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if transferrs.isEmpty && records.isEmpty {
            return 0
        }
        if !transferrs.isEmpty && !records.isEmpty {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !transferrs.isEmpty && !records.isEmpty {
            if section == 0 {
                return transferrs.count
            }
            return records.count
        }
        if !transferrs.isEmpty {
            return transferrs.count
        }
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        var transferCell: SCLTransferringCell?
        var recordCell: SCLFileRecordCell?
        if section > 0 {
            recordCell = tableView.dequeueReusableCell(withIdentifier: SCLFileRecordCell.reuseIdentifier) as? SCLFileRecordCell
        } else if !transferrs.isEmpty {
            transferCell = (tableView.dequeueReusableCell(withIdentifier: SCLTransferringCell.reuseIdentifier) as? SCLTransferringCell)
        } else if !records.isEmpty {
            recordCell = tableView.dequeueReusableCell(withIdentifier: SCLFileRecordCell.reuseIdentifier) as? SCLFileRecordCell
        }
        if let transferCell {
            let model = transferrs[indexPath.row]
            transferCell.set(imageName: "icon_file_\(model.fileType.rawValue)", name: model.name, status: model.status, progress: model.progress) { [weak self] in
                self?.onCancelTransfer?(model.taskId)
            }
            return transferCell
        } else if let recordCell {
            let model = records[indexPath.row]
            recordCell.setName(model.record.fullName)
            recordCell.setTime(model.record.time)
            recordCell.setImage(UIImage(named: "icon_file_\(model.record.fileType.rawValue)"))
            recordCell.isSelected = model.isSelected
            if recordCell.showSelectionView != tableView.isEditing {
                recordCell.setEditing(tableView.isEditing, animated: true)
            }
            return recordCell
        }
        return UITableViewCell()
    }
}

extension SCLFileRecordViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.isEditing == true else {
            guard transferType == .receive else {
                return
            }
            guard !records.isEmpty else {
                return
            }
            if (!transferrs.isEmpty && indexPath.section > 0) || transferrs.isEmpty {
                let model = records[indexPath.row]
                guard
                    model.record.fileType != .folder,
                    model.record.fileType != .compressed else {
                    self.toast("暂不支持预览此类型文件")
                    return
                }
                previewFile = model.record
                let previewController = QLPreviewController()
                previewController.navigationController?.navigationBar.barTintColor = .blue
                previewController.dataSource = self
                previewController.delegate = self
                present(previewController, animated: true, completion: nil)
            }
            return
        }
        guard !records.isEmpty else {
            return
        }
        if !transferrs.isEmpty {
            guard indexPath.section > 0 else {
                return
            }
        }
        let isSelected = records[indexPath.row].isSelected
        records[indexPath.row].isSelected = !isSelected
//        self.records = records
//        self?.dataSource.accept(records)
        let selectedRecords = records.filter({ $0.isSelected })
        onSelectedRecordsChanged?(selectedRecords)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension SCLFileRecordViewController : QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
}

extension SCLFileRecordViewController : QLPreviewControllerDelegate {
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.darkText], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.darkText], for: .highlighted)
        let path = SLTransferManager.share().filesPath() + previewFile!.fullPath
        return URL.init(fileURLWithPath: path) as QLPreviewItem
    }
    
    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear], for: .highlighted)
    }
}
