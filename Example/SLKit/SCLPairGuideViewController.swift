//
//  SCLPairGuideViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/19.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import SLKit

class SCLPairGuideViewController: SCLBaseViewController {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var cancelBtn: UIButton!
    @IBOutlet private weak var pairBtn: UIButton!
    @IBOutlet private weak var pairedBtn: UIButton!
    @IBOutlet private weak var pairedBtnHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var pairedBtnBottomConstraint: NSLayoutConstraint!
    
    private var cancel: (() -> Void)?
    private var pair: (() -> Void)?
    private var paired: ((_ button: UIButton) -> Void)?
    private var scrollToNext: SLCancelableWork?
    
    convenience init(
        onCancel: @escaping (() -> Void),
        onPair: @escaping (() -> Void),
        onPaired: @escaping ((_ button: UIButton) -> Void)
    ) {
        self.init()
        self.cancel = onCancel
        self.pair = onPair
        self.paired = onPaired
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelBtn.layer.borderColor = UIColor.init(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1).cgColor
        pairedBtn.setBackgroundColor(color: UIColor(red: 88/255.0, green: 108/255.0, blue: 1, alpha: 1), forState: .disabled)
        pairedBtn.setBackgroundColor(color: UIColor(red: 54/255.0, green: 120/255.0, blue: 1, alpha: 0.4), forState: .disabled)
        pairedBtn.setBackgroundColor(color: UIColor(red: 54/255.0, green: 120/255.0, blue: 1, alpha: 0.4), forState: .disabled)
        setPairedBtn(hidden: true)
        scrollView.rx.willBeginDragging.subscribe { [weak self] _ in
            print("scollview willBeginDragging")
            self?.setAutoScroll(enable: false)
        }.disposed(by: disposeBag)
        scrollView.rx.didEndScrollingAnimation.subscribe { [weak self] _ in
            print("scollview didEndScrollingAnimation")
            self?.setAutoScroll(enable: true)
        }.disposed(by: disposeBag)
        scrollView.rx.didEndDragging.subscribe { [weak self] _ in
            print("scrollview didEndDragging")
            self?.setAutoScroll(enable: true)
        }.disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setAutoScroll(enable: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setAutoScroll(enable: false)
    }
    
    @IBAction private func onCancel() {
        cancel?()
    }
    
    @IBAction private func onPair() {
        pair?()
        setPairedBtn(hidden: false)
    }
    
    @IBAction private func onPaired() {
        paired?(pairBtn)
    }
    
    private func setAutoScroll(enable: Bool) {
        scrollToNext?.cancel()
        scrollToNext = nil
        if enable {
            scrollToNext = SLCancelableWork(id: "轮播配对引导\(Date().timeIntervalSince1970)", delayTime: .seconds(3), closure: { [weak self] in
                guard let self else { return }
                let pageWidth = self.scrollView.bounds.width
                let page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
                var currentPage = Int(page)
                if currentPage >= Int(self.scrollView.contentSize.width / pageWidth) {
                    currentPage = 0
                    self.scrollView.setContentOffset(.zero, animated: false)
                }
                currentPage += 1
                self.scrollView.setContentOffset(.init(x: pageWidth * CGFloat(currentPage), y: 0), animated: true)
            })
            scrollToNext?.start(at: DispatchQueue.main)
        }
    }
    
    private func setPairedBtn(hidden: Bool) {
        pairedBtn.alpha = hidden ? 1 : 0
        pairedBtnBottomConstraint.constant = hidden ? 0 : 32
        pairedBtnHeightConstraint.constant = hidden ? 0 : 44
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.pairedBtn.alpha = hidden ? 0 : 1
            self?.view.layoutIfNeeded()
        } completion: { _ in

        }
    }
}
