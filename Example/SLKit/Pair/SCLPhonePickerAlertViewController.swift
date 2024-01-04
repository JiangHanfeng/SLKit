//
//  SCLPhonePickerAlertViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/24.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class SCLPhonePickerAlertViewController: SCLBaseViewController {
    
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var tipViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tipViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    private var devices: [SCLPCPairedDevice] = []
    
    private var back: (() -> Void)?
    
    convenience init(devices: [SCLPCPairedDevice], onBack: @escaping (() -> Void)) {
        self.init()
        self.devices = devices
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
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SCLPhonePickerCell.reuseIdentifier) as! SCLPhonePickerCell
        let device = devices[indexPath.row]
        cell.nameLabel.text = device.deviceName
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
        let cell = tableView.cellForRow(at: indexPath) as! SCLPhonePickerCell
        cell.setProgress(1)
        setTipView(hidden: false)
    }
}
