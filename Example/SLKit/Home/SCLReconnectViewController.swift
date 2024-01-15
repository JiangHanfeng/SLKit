//
//  SCLReconnectViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/28.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift

class SCLReconnectViewController: SCLBaseViewController {

    private var duration: Int
    private let animationImageView = UIImageView()
    private let hintLabel = UILabel()
    
    init(duration: Int) {
        self.duration = duration
        super.init(nibName: nil, bundle: nil)
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .overFullScreen
        Observable<Int>.interval(RxTimeInterval.seconds(1), scheduler: SerialDispatchQueueScheduler(internalSerialQueueName: "reconnect"))
            .observe(on: MainScheduler())
            .subscribe(onNext: { _ in
                self.duration -= 1
                if self.duration > 0 {
                    self.updateText(seconds: self.duration)
                } else {
                    // TODO: 取消连接
                    self.dismiss(animated: true, completion: nil)
                }
            }).disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        self.duration = 30
        super.init(coder: coder)
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .init(white: 0.9, alpha: 0.2)
        
        var animationImages: [UIImage] = []
        for i in 0..<35 {
            guard let img = UIImage.init(named: "icon_connecting_animation\(i)") else {
                continue
            }
            animationImages.append(img)
        }
        animationImageView.animationImages = animationImages
        animationImageView.startAnimating()
        updateText(seconds: duration)
        
        let contentView = UIView()
        contentView.backgroundColor = .white
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 16
        
        contentView.addSubview(animationImageView)
        contentView.addSubview(hintLabel)

        animationImageView.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.centerX.equalToSuperview()
        }
        
        hintLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.top.equalTo(self.animationImageView.snp.bottom).offset(8)
        }
        
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        let tap = UITapGestureRecognizer()
        hintLabel.addGestureRecognizer(tap)
        hintLabel.isUserInteractionEnabled = true
        
        tap.rx.event.bind { [weak self] ges in
            self?.dismiss(animated: true, completion: {
                
            })
        }.disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func updateText(seconds: Int) {
        let attributedText = NSMutableAttributedString(string: "正在尝试重新连接（\(seconds)s），", attributes: [
            NSAttributedString.Key.foregroundColor:UIColor.darkText,
            NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12)
        ])
        attributedText.append(NSAttributedString(string: "点击此处取消", attributes: [
            NSAttributedString.Key.foregroundColor:UIColor(red: 88/255.0, green: 108/255.0, blue: 1, alpha: 1),
            NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12)
        ]))
        hintLabel.attributedText = attributedText
    }
}
