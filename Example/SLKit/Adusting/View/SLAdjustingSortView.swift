//
//  SLAdjustingSortView.swift
//  OMNIEnjoy
//
//  Created by shenjianfei on 2023/11/18.
//

import UIKit

class SLAdjustingSortView: UIView {
    
    private lazy var sortImageView1: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "adjusting_sort_1")
        return imageView
    }()
    
    private lazy var labal1: UIView = {
        let label = UIView()
        label.backgroundColor = UIColor.colorWithHex(hexStr: "#E8EDFF",alpha: 0.2)
        return label
    }()
    
    private lazy var sortImageView2: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "adjusting_sort_2")
        return imageView
    }()
    
    private lazy var labal2: UIView = {
        let label = UIView()
        label.backgroundColor = UIColor.colorWithHex(hexStr: "#E8EDFF",alpha: 0.2)
        return label
    }()
    
    private lazy var sortImageView3: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.init(named: "adjusting_sort_3")
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        
        self.addSubview(self.sortImageView1)
        self.sortImageView1.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
        }
        
        self.addSubview(self.labal1)
        self.labal1.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.sortImageView1.snp.right).offset(10)
            make.height.equalTo(1)
            make.width.equalTo(25)
        }
        
        self.addSubview(self.sortImageView2)
        self.sortImageView2.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalTo(self.labal1.snp.right).offset(10)
            make.top.equalTo(10)
            make.bottom.equalTo(-10)
        }
        
        self.addSubview(self.labal2)
        self.labal2.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.sortImageView2.snp.right).offset(10)
            make.height.equalTo(1)
            make.width.equalTo(25)
        }
        
        self.addSubview(self.sortImageView3)
        self.sortImageView3.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.left.equalTo(self.labal2.snp.right).offset(10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func currentIndex(_ index: Int) {
        if index < 3 {
            self.sortImageView1.image = UIImage.init(named: "adjusting_sort_1")
            self.sortImageView2.image = UIImage.init(named: "adjusting_sort_2")
            self.sortImageView3.image = UIImage.init(named: "adjusting_sort_3")
            if index == 0 {
                self.sortImageView1.image = UIImage.init(named: "adjusting_current_sort_1")
            } else if index == 1 {
                self.sortImageView1.image = UIImage.init(named: "adjusting_sort_success")
                self.sortImageView2.image = UIImage.init(named: "adjusting_current_sort_2")
            } else if index == 2 {
                self.sortImageView1.image = UIImage.init(named: "adjusting_sort_success")
                self.sortImageView2.image = UIImage.init(named: "adjusting_sort_success")
                self.sortImageView3.image = UIImage.init(named: "adjusting_current_sort_3")
            }
        }
    }
    
    func complete(result: Bool){
        self.sortImageView1.image = UIImage.init(named: "adjusting_sort_success")
        self.sortImageView2.image = UIImage.init(named: "adjusting_sort_success")
        self.sortImageView3.image = result ? UIImage.init(named: "adjusting_sort_success") :  UIImage.init(named: "adjusting_sort_fail")
    }
}
