//
//  SCLConnectionViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import SLKit
import RxSwift

class SCLConnectionViewController: SCLBaseViewController {

    enum State {
        case initialize
        case scanStarting
        case scanning(_ previewLayer: AVCaptureVideoPreviewLayer)
        
        var rawValue: Int {
            switch self {
            case .initialize:
                return 0
            case .scanStarting:
                return 1
            case .scanning(_):
                return 2
            }
        }
    }
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var bottomButton: UIButton!
    
    private var state = State.initialize {
        didSet {
            if state.rawValue != oldValue.rawValue {
                updateViews()
            } else {
                switch state {
                case .scanning(let newLayer):
                    switch oldValue {
                    case .scanning(previewLayer: let oldLayer):
                        if newLayer != oldLayer {
                            updateViews()
                        }
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
    }
    
    private lazy var session: AVCaptureSession = {         return AVCaptureSession()
    }()
   
    private lazy var output: AVCaptureMetadataOutput = {
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.global(qos: .background))
        return metadataOutput
    }()
    
    private var rectOfInterest: CGRect {
        let spacing: CGFloat = 20
//        let width = (cameraView.bounds.width < cameraView.bounds.height ? cameraView.bounds.width : cameraView.bounds.height) - spacing * 2
        return CGRect(x: spacing, y: spacing, width: cameraView.bounds.width - spacing * 2, height: cameraView.bounds.height - spacing * 2)
    }
    
    private var maskLayer: CAShapeLayer {
        let maskRect = rectOfInterest
        let path = UIBezierPath(roundedRect: cameraView.bounds, cornerRadius: 0)
        path.append(UIBezierPath(roundedRect: maskRect, cornerRadius: 4))
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.fillRule = kCAFillRuleEvenOdd
        layer.fillColor = UIColor.black.cgColor
        layer.opacity = 0.6
        
        return layer
    }
    
    private var cornerBorderLayer: CAShapeLayer {
        let rect = rectOfInterest
        let shape = CAShapeLayer()
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + 16))
        path.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + 4))
        path.addArc(withCenter: CGPoint(x: rect.origin.x + 4, y: rect.origin.y + 4), radius: 4, startAngle: Double.pi, endAngle: Double.pi * 1.5, clockwise: true)
        path.addLine(to: CGPoint(x: rect.origin.x + 16, y: rect.origin.y))
        
        path.move(to: CGPoint(x: rect.origin.x + rect.width - 16, y: rect.origin.y))
        path.addLine(to: CGPoint(x: rect.origin.x + rect.width - 4, y: rect.origin.y))
        path.addArc(withCenter: CGPoint(x: rect.origin.x + rect.width - 4, y: rect.origin.y + 4), radius: 4, startAngle: Double.pi * 1.5, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + 16))
        
        path.move(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height - 16))
        path.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height - 4))
        path.addArc(withCenter: CGPoint(x: rect.origin.x + rect.width - 4, y: rect.origin.y + rect.height - 4), radius: 4, startAngle: 0, endAngle: Double.pi / 2.0, clockwise: true)
        path.addLine(to: CGPoint(x: rect.origin.x + rect.width - 16, y: rect.origin.y + rect.height))
        
        path.move(to: CGPoint(x: rect.origin.x + 16, y: rect.origin.y + rect.height))
        path.addLine(to: CGPoint(x: rect.origin.x + 4, y: rect.origin.y + rect.height))
        path.addArc(withCenter: CGPoint(x: rect.origin.x + 4, y: rect.origin.y + rect.height - 4), radius: 4, startAngle: Double.pi / 2.0, endAngle: Double.pi, clockwise: true)
        path.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height - 16))
        
        shape.path = path.cgPath
        shape.strokeColor = UIColor.init(red: 54/255.0, green: 120/255.0, blue: 1, alpha: 1).cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 2.5
        return shape
    }
    
    private var connectedCallback: (() -> Void)?
    
    convenience init(_ connectedCallback: @escaping () -> Void) {
        self.init(nibName: "SCLConnectionViewController", bundle: Bundle.main)
        self.connectedCallback = connectedCallback
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateViews()
    }


    private func updateViews() {
        switch self.state {
        case .initialize:
            bottomButton.setImage(UIImage(named: "icon_camera_scan"), for: .normal)
            bottomButton.setTitle("扫码连接", for: .normal)
            bottomButton.setTitleColor(.white, for: .normal)
            bottomButton.backgroundColor = UIColor(red: 88/255.0, green: 108/255.0, blue: 1, alpha: 1)
            bottomButton.layer.borderColor = nil
            bottomButton.layer.borderWidth = 0
            if let sublayers = cameraView.layer.sublayers {
                for sublayer in sublayers {
                    sublayer.removeFromSuperlayer()
                }
            }
            cameraView.isHidden = true
        case .scanStarting:
            bottomButton.setImage(nil, for: .normal)
            bottomButton.setTitle("取消", for: .normal)
            bottomButton.setTitleColor(UIColor(red: 25/255.0, green: 25/255.0, blue: 25/255.0, alpha: 1), for: .normal)
            bottomButton.backgroundColor = .white
            bottomButton.layer.borderColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1).cgColor
            bottomButton.layer.borderWidth = 1
        case .scanning(let previewLayer):
            bottomButton.setImage(nil, for: .normal)
            bottomButton.setTitle("取消", for: .normal)
            bottomButton.setTitleColor(UIColor(red: 25/255.0, green: 25/255.0, blue: 25/255.0, alpha: 1), for: .normal)
            bottomButton.backgroundColor = .white
            bottomButton.layer.borderColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1).cgColor
            bottomButton.layer.borderWidth = 1
            if let sublayers = cameraView.layer.sublayers {
                for sublayer in sublayers {
                    sublayer.removeFromSuperlayer()
                }
            }
            for subview in cameraView.subviews {
                subview.removeFromSuperview()
            }
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer.frame = cameraView.bounds
            cameraView.layer.addSublayer(previewLayer)
            cameraView.layer.addSublayer(maskLayer)
            cameraView.layer.addSublayer(cornerBorderLayer)
            cameraView.isHidden = false
        }
    }
    
    @IBAction func onBottomBtn() {
        switch state {
        case .initialize:
//            connectedCallback?()
//            break
            state = .scanStarting
            startCamera(previewSize: CGSize(width: cameraView.bounds.width, height: cameraView.bounds.height), rectOfInterest: rectOfInterest) { error, previewLayer in
                if let error {
                    let e = error as NSError
                    if e.code == NSURLErrorUserCancelledAuthentication {
                        self.state = .initialize
                        let alert = UIAlertController(title: "提示", message: "未授权使用相机，请设置允许访问相机", preferredStyle: .alert)
                        let cancel = UIAlertAction(title: "取消", style: .cancel)
                        let ok = UIAlertAction(title: "好的", style: .default) { _ in
                            let scheme = "App-Prefs:root=General"
                            if let url = URL(string: scheme) {
                                UIApplication.shared.open(url)
                            }
                        }
                        alert.addAction(cancel)
                        alert.addAction(ok)
                        self.present(alert, animated: true)
                    } else {
                        self.toast(error.localizedDescription)
                    }
                } else if let previewLayer {
                    self.state = .scanning(previewLayer)
                }
            }
        case .scanStarting:
            break
        case .scanning(previewLayer: _):
            stopCamera {
                self.state = .initialize
            }
        }
    }

}

extension SCLConnectionViewController: AVCaptureMetadataOutputObjectsDelegate {
    private func startCamera(previewSize: CGSize, rectOfInterest: CGRect, completion: @escaping (_ error: Error?, _ previewLayer: AVCaptureVideoPreviewLayer?) -> Void) {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            AVCaptureDevice.requestAccess(for: .video) { result in
                DispatchQueue.main.async {
                    if result {
                        self.startCamera(previewSize: previewSize, rectOfInterest: rectOfInterest, completion: completion)
                    } else {
                        let error = NSError(domain: NSErrorDomain(string: "SCLHomeViewController.startCamera.AVCaptureDevice.requestAccess") as String, code: NSURLErrorUserCancelledAuthentication, userInfo: [NSLocalizedDescriptionKey:"您拒绝了本应用使用相机"])
                        completion(error, nil)
                    }
                }
            }
            return
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            let error = NSError(domain: NSErrorDomain(string: "SCLHomeViewController.startCamera.AVCaptureDevice.requestAccess") as String, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey:"无法获取广角镜头"])
            DispatchQueue.main.async {
                completion(error, nil)
            }
            return
        }
        
        do {
            if session.inputs.isEmpty {
                let input = try AVCaptureDeviceInput(device: device)
                guard session.canAddInput(input) else {
                    let error = NSError(domain: NSErrorDomain(string: "SCLHomeViewController.startCamera.AVCaptureDevice.requestAccess") as String, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey:"AVCaptureSession can't add AVCaptureDeviceInput"])
                    completion(error, nil)
                    return
                }
                session.addInput(input)
            }
            
            if session.outputs.isEmpty {
                guard session.canAddOutput(output) else {
                    let error = NSError(domain: NSErrorDomain(string: "SCLHomeViewController.startCamera.AVCaptureDevice.requestAccess") as String, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey:"AVCaptureSession can't add AVCaptureMetadataOutput"])
                    completion(error, nil)
                    return
                }
                session.addOutput(output)
            }
            
            if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            } else if session.canSetSessionPreset(.medium) {
                session.sessionPreset = .medium
            } else if session.canSetSessionPreset(.low) {
                session.sessionPreset = .low
            } else {
                let error = NSError(domain: NSErrorDomain(string: "SCLHomeViewController.startCamera.AVCaptureDevice.requestAccess") as String, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey:"No available preset found for AVCaptureSession"])
                completion(error, nil)
                return
            }
//            session?.beginConfiguration()
            
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            captureVideoPreviewLayer.frame = CGRect(origin: .zero, size: previewSize)

            DispatchQueue.global(qos: .background).async { [weak self] in
//                DispatchQueue.main.async {
//                    completion(nil, captureVideoPreviewLayer)
//                }
//                self?.session.commitConfiguration()
                self?.session.startRunning()
                // 添加识别区域必须在layer有不为0的frame且session已经startRunning过后
                DispatchQueue.main.async {
                    let rect = captureVideoPreviewLayer.metadataOutputRectConverted(fromLayerRect: rectOfInterest)
                    self?.output.rectOfInterest = rect
                    completion(nil, captureVideoPreviewLayer)
                }
            }
        } catch let e {
            completion(e, nil)
        }
    }
    
    func stopCamera(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0 else {
            return
        }
        
        stopCamera {
            self.state = .initialize
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            let object = metadataObjects.first! as! AVMetadataMachineReadableCodeObject
            if let string = object.stringValue, let url = URL(string: string), let parameters = url.parameters, let result = SCLQRResult.deserialize(from: parameters), result.available {
                Task {
                    do {
                        let socket = try await SLSocketManager.shared.asyncConnectServer(host: "192.168.3.170", port: 8088)
                        self.toast("socket连接成功")
                    } catch let error {
                        self.toast("socket连接失败")
                        SLLog.debug("socket连接失败:\n\(error.localizedDescription)")
                    }
                }
//                let scan = Observable.create { subscriber in
//                    Task {
//                        do {
//                            let device = try await SLConnectivityManager.shared.asyncScan(deviceBuilder: SLFreeStyleDeviceBuilder.self, timeout: .seconds(10)) { device in
//                                device.macString?.elementsEqual(result.deviceMac) == true
//                            }
//                            subscriber.onNext(device)
//                            subscriber.onCompleted()
//                        } catch let error {
//                            subscriber.onError(error)
//                        }
//                    }
//                    return Disposables.create()
//                }
//            
//                scan.flatMap({ device in
//                        SLLog.debug("已找到设备：\(device.name)")
//                        return Observable.create { observer in
//                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
//                                observer.onNext(device)
//                                observer.onCompleted()
//                            })
//                            return Disposables.create()
//                        }
//                    })
//                    .subscribe(onNext: { device in
//                        SLLog.debug("已连接设备：\(device.name)")
//                    }, onError: { error in
//                        (error as? SLError).map {
//                            self.toast($0.localizedDescription)
//                        }
//                    })
//                    .disposed(by: self.disposeBag)

            } else {
                
                self.toast("请扫描超级互联Lite二维码")
            }
        }
    }
}
