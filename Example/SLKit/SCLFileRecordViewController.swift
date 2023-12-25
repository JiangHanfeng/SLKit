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
    case audio, compressed, folder, image, text, video
}

enum SCLFileTransferType {
    case receive, send
}

struct SCLFileRecord {
    let name: String
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
    private var onSelectedRecordsChanged: ((_ selectedRecords: [Any]) -> Void)?
    
    private let tableView = UITableView()
    private var records: [SCLFileRecordCellModel] = []
    private let dataSource = BehaviorRelay(value: [SCLFileRecordCellModel]())
    
    
    init(
        transferType: SCLFileTransferType,
        enterEditing: @escaping (() -> Void),
        selectedRecordsChanged: @escaping ((_ selectedRecords: [Any]) -> Void)
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
        tableView.register(UINib(nibName: String(describing: SCLFileRecordCell.self), bundle: Bundle.main), forCellReuseIdentifier: SCLFileRecordCell.reuseIdentifier)
        
        dataSource.bind(to: tableView.rx.items(cellIdentifier: SCLFileRecordCell.reuseIdentifier, cellType: SCLFileRecordCell.self)) { [unowned self] (row, model, cell) in
            cell.setName(model.record.name)
            cell.setTime(model.record.time)
            cell.setImage(UIImage(named: "icon_file_\(model.record.fileType.rawValue)"))
            cell.isSelected = model.isSelected
            cell.setEditing(self.tableView.isEditing, animated: true)
        }.disposed(by: disposeBag)
        tableView.rx.itemSelected.subscribe { [weak self] indexPath in
            self?.onSelectedRecordsChanged?([1])
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
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            self.records.append(SCLFileRecordCellModel(record: SCLFileRecord(name: "name", time: "time", fileType: .compressed, transferType: .send), isSelected: true))
            self.dataSource.accept(self.records)
        })
    }
    
    func cancelEdit() {
        tableView.setEditing(false, animated: true)
    }
    
    func selectAll() {
        
    }
}
