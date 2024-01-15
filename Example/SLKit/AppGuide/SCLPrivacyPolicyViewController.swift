//
//  SCLPrivacyPolicyViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/19.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SCLPrivacyPolicyViewController: SCLBaseViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var privacyPolicyCheckBtn: UIButton!
    @IBOutlet weak var privacyPolicyLabel: UILabel!
    @IBOutlet weak var dataCollectionCheckBtn: UIButton!
    @IBOutlet weak var dataCollectionLabel: UILabel!
    
    private var agreedAll: ((Bool) -> Void)?
    
    convenience init(_ agreedAll: @escaping ((_ allAgreed: Bool) -> Void)) {
        self.init()
        self.agreedAll = agreedAll
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                guard let currentPage = self?.pageControl.currentPage else {
                    return
                }
                self?.scrollView.setCurrentPage(currentPage)
            })
            .disposed(by: disposeBag)
        scrollView.rx.currentPage
            .subscribe(onNext: { [weak self] in
                print($0)
                self?.pageControl.currentPage = $0
            })
            .disposed(by: disposeBag)
        let clickableColor = UIColor.init(red: 88/255.0, green: 108/255.0, blue: 1, alpha: 1)
        let privacyPolicyText = NSAttributedString(string: "《联想隐私声明》", attributes: [
            NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor:clickableColor
        ])
        let userAgreementText = NSAttributedString(string: "《用户许可协议》", attributes: [
            NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor:clickableColor
        ])
        
        let tap1 = UITapGestureRecognizer()
        privacyPolicyLabel.addGestureRecognizer(tap1)
        privacyPolicyLabel.isUserInteractionEnabled = true
        
        tap1.rx.event.bind { [weak self] ges in
            guard let label = self?.privacyPolicyLabel, let totalString = label.attributedText?.string else {
                return
            }
            if ges.didTapAttributedTextInLabel(label: label, inRange: (totalString as NSString).range(of: privacyPolicyText.string)) {
                self?.navigationController?.show(SLWebViewController(privacyPolicyText.string, "https://www.lenovo.com/privacy/"), sender: nil)
            } else if ges.didTapAttributedTextInLabel(label: label, inRange: (totalString as NSString).range(of: userAgreementText.string)) {
                self?.navigationController?.show(SLWebViewController(userAgreementText.string, "https://support.lenovo.com/us/en/solutions/ht100141"), sender: nil)
            } else if let isSelected = self?.privacyPolicyCheckBtn.isSelected {
                self?.privacyPolicyCheckBtn.isSelected = !isSelected
//                self?.agreedAll?((self?.dataCollectionCheckBtn.isSelected ?? false) && !isSelected)
                self?.agreedAll?(!isSelected)
            }
        }.disposed(by: disposeBag)
        
        let tap2 = UITapGestureRecognizer()
        dataCollectionLabel.addGestureRecognizer(tap2)
        dataCollectionLabel.isUserInteractionEnabled = true
        
        tap2.rx.event.bind { [weak self] ges in
            if let isSelected = self?.dataCollectionCheckBtn.isSelected {
                self?.dataCollectionCheckBtn.isSelected = !isSelected
//                self?.agreedAll?((self?.privacyPolicyCheckBtn.isSelected ?? false) && !isSelected)
            }
        }.disposed(by: disposeBag)
        
        let btns = [privacyPolicyCheckBtn!, dataCollectionCheckBtn!]
        let selects = btns.map { button in
            button.rx.tap.scan(false) { state, _ in
                !state
            }
            .startWith(false)
            .share(replay: 1)
        }
        for (button, select) in zip(btns, selects) {
            select.bind(to: button.rx.isSelected).disposed(by: disposeBag)
        }
        Observable.combineLatest(selects[0..<1])
            .subscribe(onNext: { [weak self] in
                self?.agreedAll?($0.allSatisfy { selected in
                    selected
                })
            })
            .disposed(by: disposeBag)
    }

}

public extension Reactive where Base: UIScrollView {
    var currentPage: Observable<Int> {
        return didEndDecelerating.map {
            let pageWidth = self.base.bounds.width
            let page = floor((self.base.contentOffset.x - pageWidth / 2) / pageWidth) + 1
            return Int(page)
        }
    }
}

public extension UIScrollView {
    func setCurrentPage(_ page: Int, animated: Bool = true) {
        var rect = bounds
        rect.origin.x = rect.width * CGFloat(page)
        rect.origin.y = 0
        scrollRectToVisible(rect, animated: animated)
    }
}

fileprivate extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)

        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,y:(labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x:locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y:locationOfTouchInLabel.y - textContainerOffset.y);
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

