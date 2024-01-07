//
//  SCLFileRecordViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/25.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import RxCocoa
//import RxSwift

enum SCLFileType: String {
    case audio, compressed, excel, folder, image, pdf, ppt, text, video, word
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
    
    private let tableView = UITableView()
    private var records: [SCLFileRecordCellModel] = []
    private let dataSource = BehaviorRelay(value: [SCLFileRecordCellModel]())
    
    
    init(
        transferType: SCLFileTransferType,
        enterEditing: @escaping (() -> Void),
        selectedRecordsChanged: @escaping ((_ selectedRecords: [SCLFileRecordCellModel]) -> Void)
    ) {
        self.transferType = transferType
        self.onEnterEditing = enterEditing
        self.onSelectedRecordsChanged = selectedRecordsChanged
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
        
        dataSource.bind(to: tableView.rx.items(cellIdentifier: SCLFileRecordCell.reuseIdentifier, cellType: SCLFileRecordCell.self)) { [unowned self] (row, model, cell) in
            cell.setName(model.record.name)
            cell.setTime(model.record.time)
            cell.setImage(UIImage(named: "icon_file_\(model.record.fileType.rawValue)"))
            cell.isSelected = model.isSelected
            if cell.showSelectionView != tableView.isEditing {
                cell.setEditing(tableView.isEditing, animated: true)
            }
        }.disposed(by: disposeBag)
        tableView.rx.itemSelected.subscribe { [weak self] indexPath in
            guard self?.tableView.isEditing == true else {
                return
            }
            if var records = self?.records {
                let isSelected = records[indexPath.row].isSelected
                records[indexPath.row].isSelected = !isSelected
                self?.records = records
                self?.dataSource.accept(records)
                if let selectedRecords = self?.records.filter({ $0.isSelected }) {
                    self?.onSelectedRecordsChanged?(selectedRecords)
                }
            }
        }.disposed(by: disposeBag)
        
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
                    self?.dataSource.accept(records)
                    self?.onSelectedRecordsChanged?([])
                }
            }
        }
    }
    
    func selectAll() {
        records = records.map { item in
            var newItem = item
            newItem.isSelected = true
            return newItem
        }
        dataSource.accept(records)
        onSelectedRecordsChanged?(records.filter({ $0.isSelected }))
    }
    
    func updateDataSource(_ models: [SCLFileRecordCellModel]) {
        DispatchQueue.main.async {
            self.records = models
            self.dataSource.accept(models)
        }
    }
    
    func updateTransferringFiles() {
        
    }
}
