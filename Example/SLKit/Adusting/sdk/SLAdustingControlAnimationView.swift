//
//  SLAdustingAnimationView.swift
//  test
//
//  Created by shenjianfei on 2024/1/5.
//

import UIKit

class SLAdustingControlAnimationView: UIView {
    
    private var isAnimation: Bool = false
    private var emitterLayer = CAEmitterLayer()
    private lazy var showEmitter: CAEmitterLayer = {
        
        let snowEmitter = CAEmitterLayer()
        snowEmitter.emitterShape = CAEmitterLayerEmitterShape.rectangle
        
        var cells: [CAEmitterCell] = []
        let colors: [UIColor] = [UIColor.init(white: 0.56, alpha: 0.8),
                                 UIColor.white,
                                 UIColor.blue,
                                 UIColor.red,
                                 UIColor.green,
                                 UIColor.yellow,
                                 UIColor.orange]
        
        for color in colors {
            
            let cell1 = self.emitterCell(size: CGSize.init(width: 18, height: 18),
                                         backgroundColor: UIColor.init(white: 0.56, alpha: 0.8),
                                         borderWidth: 0,
                                         borderColor: color)
            
            let cell2 = self.emitterCell(size: CGSize.init(width: 26, height: 26),
                                         backgroundColor: UIColor.init(white: 0.56, alpha: 0.8),
                                         borderWidth: 4,
                                         borderColor: color)
            
            cells.append(cell1)
            cells.append(cell2)
        }
        
        snowEmitter.emitterCells = cells
        
        return snowEmitter
    }()

    func startAnimation(){
        if self.isAnimation {
            return
        }
        self.isAnimation = true
        self.layer.insertSublayer(self.emitterLayer, at: 0)
    }
    
    func endAnimation(){
        if !self.isAnimation {
            return
        }
        self.isAnimation = false
        self.emitterLayer.removeFromSuperlayer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.emitterLayer.frame = self.bounds
        self.emitterLayer.emitterPosition = CGPoint(x: self.bounds.width/2.0, y: self.bounds.height/2.0)
        self.emitterLayer.emitterSize = self.bounds.size
    }
}

private extension SLAdustingControlAnimationView {
    
     func emitterCell(size: CGSize,
                             backgroundColor: UIColor,
                             borderWidth: CGFloat,
                             borderColor: UIColor) -> CAEmitterCell {
        
        let view = UIView.init(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        view.backgroundColor = backgroundColor;
        view.layer.borderWidth = borderWidth;
        view.layer.borderColor = borderColor.cgColor;
        view.layer.cornerRadius = size.width/2.0;
        view.layer.masksToBounds = true;
        
        UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 1);
        if let cxt = UIGraphicsGetCurrentContext() {
            view.layer.render(in: cxt)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        let cell = CAEmitterCell()
        cell.contents = image?.cgImage
        cell.birthRate = 4;
        cell.lifetime = 0.5;
        cell.redRange = 0.4;
        cell.greenRange = 0.3;
        cell.blueRange = 0.3;
        cell.alphaRange = 0.8;
        cell.alphaSpeed = -0.1;
        
        return cell;
        
    }
    
}
