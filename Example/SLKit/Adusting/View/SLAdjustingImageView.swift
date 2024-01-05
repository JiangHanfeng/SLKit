//
//  SLAdjustingImageView.swift
//  OMNIEnjoy
//
//  Created by shenjianfei on 2023/11/18.
//

import UIKit

class SLAdjustingImageView: UIImageView {

    private var animatingRuning = false
    
    override func startAnimating() {
        if !animatingRuning {
            self.animatingRuning = true
            self.image = self.animationImages?.last
            self.animatingRun()
        }
    }

    override func stopAnimating() {
        if animatingRuning {
            self.animatingRuning = false
            super.stopAnimating()
        }
    }
    
    private func animatingRun() {
        if !self.animatingRuning {
            return
        }
        self.animationRepeatCount = 1
        self.animationDuration = 1
        super.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            super.stopAnimating()
            self.image = self.animationImages?.last
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.animatingRun()
            }
        }
    }

}
