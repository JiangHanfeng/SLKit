//
//  SCLFileHistoryViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/25.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

let SCLFileTypeMapper = [
    SLFileType.folderFileType:SCLFileType.folder,
    SLFileType.videoFileType:SCLFileType.video,
    SLFileType.imageFileType:SCLFileType.image,
    SLFileType.audioFileType:SCLFileType.audio,
    SLFileType.excelFileType:SCLFileType.excel,
    SLFileType.pdfFileType:SCLFileType.pdf,
    SLFileType.wordFileType:SCLFileType.word,
    SLFileType.pptFileType:SCLFileType.ppt,
    SLFileType.zipFileType:SCLFileType.compressed,
    SLFileType.txtFileType:SCLFileType.text
]

class SCLTransferringModel {
    let taskId: String
    let type: SCLFileTransferType
    var fileType: SCLFileType
    var name: String
    var count: Int
    var progress: Float
    var status: String
    
    init(taskId: String, type: SCLFileTransferType, fileType: SCLFileType, name: String, count: Int, progress: Float, status: String) {
        self.taskId = taskId
        self.type = type
        self.fileType = fileType
        self.name = name
        self.count = count
        self.progress = progress
        self.status = status
    }
}

class DeleteFileAction {
    let type: SCLFileTransferType
    let files: [SCLFileRecordCellModel]
    
    init(type: SCLFileTransferType, files: [SCLFileRecordCellModel]) {
        self.type = type
        self.files = files
    }
}

class SCLFileHistoryViewController: SCLBaseViewController {

    @IBOutlet private weak var receivedBtn: UIButton!
    @IBOutlet private weak var sendedBtn: UIButton!
    @IBOutlet private weak var segementView: UIView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var bottomViewTopConstraint: NSLayoutConstraint!
    private var currentIndex = 0
    private var receivingModel: SCLTransferringModel?
    private var sendingModel: SCLTransferringModel?
    private var shouldDeleteFiles: DeleteFileAction?
    private lazy var localFileManager: SLLocalFileManger = {
        return SLLocalFileManger()
    }()
    
    private lazy var segementLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 2
        layer.strokeColor = UIColor(red: 88/255.0, green: 108/255.0, blue: 1, alpha: 1).cgColor
        layer.lineCap = kCALineCapRound
        let path = UIBezierPath()
        path.move(to: .init(x: 0, y: 1))
        path.addLine(to: .init(x: UIScreen.main.bounds.width, y: 1))
        layer.path = path.cgPath
        return layer
    }()
    
    private lazy var receivedFileVc = {
        return SCLFileRecordViewController(transferType: .receive) { [weak self] in
            self?.startEditing(for: .receive)
        } onSelectedRecordsChanged: { [weak self] selectedRecords in
            self?.shouldDeleteFiles = DeleteFileAction(type: .receive, files: selectedRecords)
            self?.setBottomView(hidden: selectedRecords.isEmpty)
        } onCancelTransfer: { taskId in
            SLTransferManager.share().cancelFiles(withTaskId: taskId)
        }
    }()
    
    private lazy var sendedFileVc = {
        return SCLFileRecordViewController(transferType: .send) { [weak self] in
            self?.startEditing(for: .send)
        } onSelectedRecordsChanged: { [weak self] selectedRecords in
            self?.shouldDeleteFiles = DeleteFileAction(type: .send, files: selectedRecords)
            self?.setBottomView(hidden: selectedRecords.isEmpty)
        } onCancelTransfer: { taskId in
            SLTransferManager.share().cancelFiles(withTaskId: taskId)
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segementView.layer.addSublayer(segementLayer)
        
        receivedBtn.rx.tap.bind { [unowned self] _ in
            self.setSelectedIndex(0)
        }.disposed(by: disposeBag)
        sendedBtn.rx.tap.bind { [unowned self] _ in
            self.setSelectedIndex(1)
        }.disposed(by: disposeBag)
        
        let tap = UITapGestureRecognizer()
        bottomView.addGestureRecognizer(tap)
        bottomView.isUserInteractionEnabled = true
        
        tap.rx.event.bind { [weak self] ges in
            if let shouldDelete = self?.shouldDeleteFiles {
                for file in shouldDelete.files {
                    self?.localFileManager.deleteData(withPath: file.record.path, name: file.record.name, extensionName: file.record.extensionName, isSend: shouldDelete.type == .send)
                }
                self?.stopEditing()
                self?.updateFileRecords(type: shouldDelete.type)
            }
        }.disposed(by: disposeBag)
        
        setSelectedIndex(0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func setSelectedIndex(_ index: Int) {
        currentIndex = index
        let btns = [receivedBtn, sendedBtn]
        guard index < btns.count else { return }
        for (i, btn) in btns.enumerated() {
            btn?.isSelected = index == i
        }
        let btn = btns[index]!
        let btnStart = UIScreen.main.bounds.width/4 + UIScreen.main.bounds.width*0.5*CGFloat(index) - btn.bounds.width/2
        let btnEnd = btnStart + btn.bounds.width
        let start = btnStart/UIScreen.main.bounds.width
        let end = btnEnd/UIScreen.main.bounds.width
        segementLayer.strokeStart = start
        segementLayer.strokeEnd = end
        
        transitionToChild([receivedFileVc, sendedFileVc][index], removeCurrent: false) { childView in
            childView.snp.makeConstraints {[weak self] make in
                guard let self else { return }
                make.top.equalTo(self.segementView.snp.bottom).offset(20)
                make.bottom.equalTo(self.bottomView.snp.top)
                make.leading.trailing.equalTo(0)
            }
            self.updateFileRecords(type: [SCLFileTransferType.receive, .send][index])
            if index > 0 {
                self.updateSendingFiles()
            } else {
                self.updateReceivingFiles()
            }
        }
        
        stopEditing()
    }
    
    private func startEditing(for type: SCLFileTransferType) {
        navigationItem.title = "选择文件"
        let selectAllBarButtonItem = UIBarButtonItem(title: "全选", style: .plain, target: self, action: nil)
        selectAllBarButtonItem.setTitleTextAttributes([
            NSAttributedStringKey.font:UIFont.systemFont(ofSize: 15, weight: .medium),
            NSAttributedStringKey.foregroundColor:UIColor(red: 88/255.0, green: 108/255.0, blue: 1, alpha: 1)
        ], for: .normal)
        selectAllBarButtonItem.rx.tap.bind { _ in
            [self.receivedFileVc,self.sendedFileVc][self.currentIndex].selectAll()
        }.disposed(by: disposeBag)
        navigationItem.leftBarButtonItems = [selectAllBarButtonItem]
        
        let closeBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_close")?.withRenderingMode(.alwaysOriginal), style: .done, target: self, action: nil)
        closeBarButtonItem.rx.tap.bind { [weak self] _ in
            self?.stopEditing()
        }.disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = closeBarButtonItem
    }

    @objc private func stopEditing() {
        navigationItem.title = "联想闪传"
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_back_dark")?.withRenderingMode(.alwaysOriginal), style: .done, target: self, action: nil)
        backBarButtonItem.rx.tap.bind { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = backBarButtonItem
        navigationItem.rightBarButtonItem = nil
        setBottomView(hidden: true)
        
        receivedFileVc.cancelEdit()
        sendedFileVc.cancelEdit()
    }
    
    private func setBottomView(hidden: Bool) {
        guard bottomView.isHidden != hidden else {
            return
        }
        bottomView.isHidden = false
        bottomView.alpha = hidden ? 1 : 0
        bottomViewTopConstraint.constant = hidden ? 0 : 45
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.bottomView.alpha = hidden ? 0 : 1
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.bottomView.isHidden = hidden
        }
    }
    
    func updateFileRecords(type: SCLFileTransferType) {
        DispatchQueue.global().async { [weak self] in
            let source = type == .receive ? SLTransferManager.share().receiveFiles() : SLTransferManager.share().sendFiles()
            var models: [SCLFileRecordCellModel] = []
            for item in source {
                let record = SCLFileRecord(
                    name: item.name,
                    fullName: item.fullFileNama(),
                    extensionName: item.extensionName,
                    path: item.path,
                    fullPath: item.fullPath(),
                    time: Int.timestamp2FormattedDataString(from: Int(item.time)),
                    fileType: SCLFileTypeMapper[item.fileType()] ?? .unknown, transferType: type)
                let cellModel = SCLFileRecordCellModel(record: record, isSelected: false)
                models.append(cellModel)
            }
            DispatchQueue.main.async { [weak self] in
                switch type {
                case .receive:
                    print("查询到\(models.count)条已接收文件")
                    self?.receivedFileVc.updateFileRecords(models)
                case .send:
                    print("查询到\(models.count)条已发送文件")
                    self?.sendedFileVc.updateFileRecords(models)
                }
            }
        }
    }
    
    func updateReceivingFiles() {
        let receivingModels = SLTransferManager.share().currentReceiveFileTransfer().filter { item in
            !item.files.isEmpty
        }.map { item in
            let name = item.files.count > 1 ? "正在接收\(item.files.first!.name)等文件" : "正在接收\(item.files.first!.name)"
            return SCLTransferringModel(taskId: item.taskId, type: .receive, fileType: SCLFileTypeMapper[item.files.first!.fileType()] ?? .unknown, name: name, count: item.files.count, progress: item.currentProgress, status: "%\(item.currentProgress * 100)")
        }
        receivedFileVc.updateTransferringFiles(receivingModels)
    }
    
    func updateSendingFiles() {
        if let sendFile = SLTransferManager.share().currentSendFileTransfer(), !sendFile.files.isEmpty {
            let sendModel = SCLTransferringModel(taskId: sendFile.taskId, type: .send, fileType: SCLFileTypeMapper[sendFile.files.first!.fileType()] ?? .unknown, name: sendFile.files.first!.name, count: sendFile.files.count, progress: sendFile.currentProgress, status: "%\(sendFile.currentProgress * 100)")
            sendedFileVc.updateTransferringFiles([sendModel])
        } else {
            sendedFileVc.updateTransferringFiles([])
        }
    }
}
