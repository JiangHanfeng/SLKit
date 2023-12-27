//
//  TestViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/11/6.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SLKit
import CoreBluetooth
import RxSwift



class TestViewController: UIViewController {
    
    @IBOutlet weak var bleOperationBtn: UIButton!
    @IBOutlet weak var bleStatusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private let pc_ble_uuid = "0000180a-0000-1000-8000-00805f9b34fb"
    
    private var isFirstAppear = true
    private var monitorTask: SLA2DPMonitorTask!
    private var devices: [SLFreeStyleDevice] = []
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    private var heartBeatWork: SLCancelableWork!
    
    private var scanTask: SLDeviceScanTask<SLFreeStyleDevice>!
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        heartBeatWork = SLCancelableWork(delayTime: .seconds(15), closure: { [weak self] in
            if let peripheral = self?.peripheral, let characteristic = self?.characteristic {
                self?.readCharacteristc(peripheral: peripheral, charateristic: characteristic)
            } else {
                SLLog.debug("未连接设备，无法读取charateristic")
            }
            self?.heartBeatWork.start(at: DispatchQueue.main)
        })
        bleStatusLabel.backgroundColor = UIColor(displayP3Red: 0, green: 84/255.0, blue: 166/255.0, alpha: 0.4)
        bleOperationBtn.addTarget(self, action: #selector(onBleOperation), for: .touchUpInside)
        
//        scanTask = SLDeviceScanTask(anyDevice: SLAnyDevice(base: SLFreeStyleDeviceBuilder.self)) { [weak self] devices in
//            self?.devices = devices
//            self?.tableView.reloadData()
//        } exceptionHandler: { error in
//            
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isFirstAppear else { return }
        isFirstAppear = false
//        scanTask.start()
//        let str = "https://3slink.com/app/ios"
//        guard let url = URL(string: str) else { return }
//        let can = UIApplication.shared.canOpenURL(url)
//        if can {
//            if #available(iOS 10.0, *) {
//                UIApplication.shared.open(url, options: [:]) { (b) in
//                    
//                }
//            } else {
//                //iOS 10 以前
//                UIApplication.shared.openURL(url)
//            }
//        }
//        return
//        let scanTask = SLBleScanTask {
//            SLLog.debug("开始扫描")
//        } stoppedCallback: {
//            SLLog.debug("扫描结束")
//        }
//        
//        scanTask.peripheralDiscoveredCallback = { [weak scanTask, weak self] (peripheral, _, _) in
//            if peripheral.name?.elementsEqual("蒋函锋的Mac mini") == true {
//                SLLog.debug("找到外设:蒋函锋的Mac mini")
//                scanTask?.stop()
//                let connection = SLBleConnection(peripheral: peripheral) { _ in
//                    SLLog.debug("开始连接\(peripheral.name!)")
//                } connectionCompletion: { _, result, error in
//                    if result {
//                        SLLog.debug("连接\(peripheral.name!)成功")
//                        self?.peripheral = peripheral
//                        self?.bleOperationBtn.setTitle("断开连接", for: .normal)
//                        let discoverService = SLBleServiceDiscoverTask(peripheral: peripheral) {
//                            SLLog.debug("开始搜索service")
//                        } completion: { services, error in
//                            if let service = services.first(where: { item in
//                                SLLog.debug("找到service:\(item.uuid.uuidString)")
//                                return item.uuid.uuidString.elementsEqual("198D")
//                            }) {
//                                let discoverCharacteristic = SLBleCharacteristicDiscoverTask(peripheral: peripheral, service: service) {
//                                    SLLog.debug("开始搜索charateristic")
//                                } completion: { charateristics, error in
//                                    if let charateristic = charateristics.first(where: { item2 in
//                                        item2.uuid.uuidString.elementsEqual("2A37")
//                                    }) {
//                                        SLLog.debug("找到charateristic：2A37")
//                                        self?.characteristic = charateristic
//                                        self?.heartBeatWork.startImmediately(at: DispatchQueue.main)
//                                    }
//                                }
//                                try? discoverCharacteristic.start()
//                            } else {
//                                SLLog.debug("未找到service")
//                            }
//                        }
//                        try? discoverService.start()
//                    } else {
//                        SLLog.debug("连接失败")
//                    }
//                } conectionDisconnected: { _ in
//                    SLLog.debug("连接已断开")
//                    self?.peripheral = nil
//                    self?.characteristic = nil
//                    self?.heartBeatWork.cancel()
//                }
//                try? connection.start()
//            }
//        }
//        try? scanTask.start()
    }
    
    @objc private func onBleOperation() {
        if let _ = self.peripheral {
            SLConnectivityManager.shared.disconnectDevice()
        }
    }
    
    private func readCharacteristc(peripheral: CBPeripheral, charateristic: CBCharacteristic) {
        let task = SLReadCharacteristicTask(peripheral: peripheral, characteristic: charateristic) {
            SLLog.debug("开始读取characteristc")
        } completion: { data, error in
            if let data, let string = String(data: data, encoding: .utf8) {
                SLLog.debug("读取characteristc完成，返回数据：\(string)")
            } else if let error {
                SLLog.debug("读取characteristc完成，发生异常：\(error.localizedDescription)")
            } else {
                SLLog.debug("读取characteristc完成，数据无法解析")
            }
        }
        try? task.start()
    }
    
    deinit {
//        try? monitorTask.stop()
//        log("\(self) deinit")
        scanTask.terminate()
        SLLog.debug("\(self) deinit")
    }
}

extension TestViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "reuse")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuse")
            cell?.selectionStyle = .none
        }
        let device = devices[indexPath.row]
        cell!.textLabel?.text = device.name
        var detail = ""
        if let mac = device.macString {
            detail += "MAC:\(mac) "
        }
        if let host = device.host {
            detail += "连接地址:\(host)"
        }
        cell!.detailTextLabel?.text = detail
        return cell!
    }
}
