//
//  SCLFileHistoryViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/25.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLFileHistoryViewController: SCLBaseViewController {

    @IBOutlet private weak var receivedBtn: UIButton!
    @IBOutlet private weak var sendedBtn: UIButton!
    @IBOutlet private weak var segementView: UIView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var bottomViewTopConstraint: NSLayoutConstraint!
    
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
        return SCLFileRecordViewController(transferType: .receive) {
            
        } selectedRecordsChanged: { [unowned self] selectedRecords in
            self.setBottomView(hidden: selectedRecords.isEmpty)
        }
    }()
    
    private lazy var sendedFileVc = {
        return SCLFileRecordViewController(transferType: .send) {
            
        } selectedRecordsChanged: { selectedRecords in
            
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
        
        setSelectedIndex(0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func setSelectedIndex(_ index: Int) {
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
            childView.snp.makeConstraints { make in
                make.top.equalTo(self.segementView.snp.bottom).offset(20)
                make.bottom.equalTo(self.bottomView.snp.top)
                make.leading.trailing.equalTo(0)
            }
        }
    }
    
    private func setIsEditing(_ isEditing: Bool) {
        if isEditing {
            navigationItem.title = "选择文件"
            let selectAllBarButtonItem = UIBarButtonItem(title: "全选", style: .plain, target: self, action: nil)
            selectAllBarButtonItem.setTitleTextAttributes([
                NSAttributedStringKey.font:UIFont.systemFont(ofSize: 15, weight: .medium),
                NSAttributedStringKey.foregroundColor:UIColor(red: 88/255.0, green: 108/255.0, blue: 1, alpha: 1)
            ], for: .normal)
            selectAllBarButtonItem.rx.tap.bind { _ in
                self.receivedFileVc.selectAll()
            }.disposed(by: disposeBag)
            navigationItem.leftBarButtonItems = [selectAllBarButtonItem]
            
            let closeBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_close")?.withRenderingMode(.alwaysOriginal), style: .done, target: self, action: nil)
            closeBarButtonItem.rx.tap.bind { _ in
                self.receivedFileVc.cancelEdit()
                self.setIsEditing(false)
            }.disposed(by: disposeBag)
            navigationItem.rightBarButtonItem = closeBarButtonItem
        } else {
            navigationItem.title = "联想闪传"
            let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_back_dark")?.withRenderingMode(.alwaysOriginal), style: .done, target: self, action: nil)
            backBarButtonItem.rx.tap.bind { _ in
                self.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
            navigationItem.leftBarButtonItem = backBarButtonItem
            navigationItem.rightBarButtonItem = nil
            setBottomView(hidden: true)
        }
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
}
