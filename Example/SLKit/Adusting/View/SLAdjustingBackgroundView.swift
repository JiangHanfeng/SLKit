//
//  SLAdjustingBackgroundView.swift
//  OMNIEnjoy
//
//  Created by shenjianfei on 2024/1/2.
//

import UIKit

private struct TouchUtil {
    static let defaultSize = CGSize(width: 18.6, height: 18.6)
    static let highlightSize = CGSize(width: 18.2, height: 18.2)
    static let defaultColor = UIColor(white: 0.56, alpha: 0.58)
    static let highlightColor = UIColor(white: 0.56, alpha: 0.88)
}

class SLAdjustingBackgroundView: UIView {
    
    private let emitterLayer = CAEmitterLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI() {
        self.isUserInteractionEnabled = false
        let size = TouchUtil.defaultSize
        let dot = UIView(frame: CGRect(origin: .zero, size: size))
        dot.backgroundColor = UIColor(white: 0.56, alpha: 0.95)// TouchUtil.defaultColor
        dot.layer.cornerRadius = size.width / 2
        dot.layer.masksToBounds = true
        UIGraphicsBeginImageContextWithOptions(dot.frame.size, false, 1)
        if let cxt = UIGraphicsGetCurrentContext() {
            dot.layer.render(in: cxt)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.layer.addSublayer(self.emitterLayer)

        emitterLayer.emitterShape = CAEmitterLayerEmitterShape.rectangle
        resetFrame()
        let cell = CAEmitterCell()
        cell.contents = image?.cgImage
        cell.birthRate = 12
        cell.lifetime = 1
        cell.redRange = 0.4
        cell.greenRange = 0.3
        cell.blueRange = 0.3
        cell.alphaRange = 0.8
        cell.alphaSpeed = -0.1
        emitterLayer.emitterCells = [cell]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resetFrame()
    }
    
    private func resetFrame() {
        let rect = self.bounds
        emitterLayer.frame = rect
        emitterLayer.emitterPosition = CGPoint(x: rect.width / 2, y: rect.height / 2)
        emitterLayer.emitterSize = rect.size
    }
}
