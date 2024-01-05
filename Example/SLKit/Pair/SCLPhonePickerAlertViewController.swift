//
//  SCLPhonePickerAlertViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/24.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SLKit

class SCLPhonePickerAlertViewController: SCLBaseViewController {
    
    class Model {
        let device: SCLPCPairedDevice
        var progress: CGFloat
        var verifyResult: Bool? = nil
        
        init(device: SCLPCPairedDevice, progress: CGFloat, verifyResult: Bool? = nil) {
            self.device = device
            self.progress = progress
            self.verifyResult = verifyResult
        }
    }
    
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var tipViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tipViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    private var socket: SLSocketClient?
    private var models: [Model] = []
    
    private var onVerified: ((_ device: SCLPCPairedDevice) -> Void)?
    private var back: (() -> Void)?
    
    convenience init(socket: SLSocketClient, devices: [SCLPCPairedDevice], onVerified: @escaping ((SCLPCPairedDevice) -> Void), onBack: @escaping (() -> Void)) {
        self.init()
        self.socket = socket
        self.models = devices.map({Model(device: $0, progress: 0)})
        self.onVerified = onVerified
        self.back = onBack
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: String(describing: SCLPhonePickerCell.self), bundle: Bundle.main), forCellReuseIdentifier: SCLPhonePickerCell.reuseIdentifier)
        tableViewHeightConstraint.constant = 52.0 * 3 + 35
    }
    
    @IBAction func onBack() {
        back?()
    }
    
    private func setTipView(hidden: Bool) {
        tipView.alpha = hidden ? 1 : 0
        tipViewTopConstraint.constant = hidden ? 0 : 12
        tipViewHeightConstraint.constant = hidden ? 0 : UIScreen.main.bounds.width < 375 ? 81.5 : 67
        UIView.animate(withDuration: 0.25) {
            self.tipView.alpha = hidden ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
}

extension SCLPhonePickerAlertViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SCLPhonePickerCell.reuseIdentifier) as! SCLPhonePickerCell
        let model = models[indexPath.row]
        cell.nameLabel.text = model.device.deviceName
        cell.setProgress(model.progress, result: model.verifyResult)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: .init(origin: .zero, size: .init(width: 1, height: 16)))
        return view
    }

}

extension SCLPhonePickerAlertViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let verifingIndex = models.firstIndex { $0.progress != 0 && $0.verifyResult == nil }
        if verifingIndex == nil {
            models[indexPath.row].progress = 0.5
            tableView.reloadRows(at: [indexPath], with: .automatic)
            if let socket {
                SLSocketManager.shared.send(SCLPairVerificationReq(device: models[indexPath.row].device), from: socket, for: SCLSocketResponse<SCLSocketGenericContent>.self) { [weak self] result in
                    DispatchQueue.main.async {
                        var success = false
                        switch result {
                        case .success(let resp):
                            success = resp.state == 1
                        case .failure(let e):
                            SLLog.debug("蓝牙配对校验error:\(e.localizedDescription)")
                        }
                        self?.models[indexPath.row].progress = success ? 1 : 0
                        self?.models[indexPath.row].verifyResult = success
                        self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                        if success, let device = self?.models[indexPath.row].device {
                            self?.onVerified?(device)
                        } else {
                            self?.toast("蓝牙配对校验未通过")
                        }
                    }
                }
            } else {
                let presentingVc = presentingViewController
                presentingVc?.dismiss(animated: true) {
                    presentingVc?.toast("已断开连接")
                }
            }
        } else if verifingIndex != indexPath.row {
            let model = models[verifingIndex!]
            toast("等待校验\(model.device.deviceName)的结果，请勿选择其他设备")
        }
//        setTipView(hidden: false)
    }
}
