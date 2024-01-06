//
//  SLBLEBackgroundTask.swift
//  Vehicle
//
//  Created by shenjianfei on 2023/9/6.
//

import UIKit
import CoreBluetooth
import SLKit

class SLBLEBackgroundTask: NSObject {

    private var peripheralManager: CBPeripheralManager?
    private var service: CBUUID?
    private var localMac: String?
    
    private lazy var advertisingDispatchQueue: DispatchQueue = {
        return DispatchQueue.init(label: "com.background.run")
    }()
    
    func start(_ localMac: String?){
        self.localMac = localMac?.replacingOccurrences(of: ":", with: "")
        if self.peripheralManager == nil {
            self.peripheralManager = CBPeripheralManager.init(delegate: self,
                                                              queue: self.advertisingDispatchQueue,
                                                              options: [CBCentralManagerOptionShowPowerAlertKey : false])
        } else {
            if self.peripheralManager?.state == .poweredOn {
                self.addService()
            }
        }
    }
    
    func stop(){
        self.peripheralManager?.removeAllServices()
    }
    
    private func addService(){
        self.peripheralManager?.removeAllServices()
        
        if let macStr = self.localMac,
           macStr.count == 12 {
            let service = CBUUID.init(string: "beda5d14-6723-48c0-ae4a-\(macStr)")
            let characteristics = CBMutableCharacteristic.init(type: CBUUID.init(string: "beda5d14-6723-48c0-ae4a-ae3cac92712a"),
                                                               properties: [.write],
                                                               value: nil,
                                                               permissions: [.writeable])
            let serviceM = CBMutableService.init(type: service, primary: true)
            serviceM.characteristics = [characteristics]
            self.service = service
            self.peripheralManager?.add(serviceM)
        }
        
        let service1 = CBUUID.init(string: "beda5d14-6723-0000-0000-000000000000")
        let serviceM1 = CBMutableService.init(type: service1, primary: true)
        self.peripheralManager?.add(serviceM1)
    }
}

extension SLBLEBackgroundTask: CBPeripheralManagerDelegate {
    //状态发生改变
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        DispatchQueue.main.async {
            if peripheral.state == .poweredOn {
                self.addService()
            } else {
                self.peripheralManager?.stopAdvertising()
                self.peripheralManager?.removeAllServices()
            }
        }
    }

    // 当你执行addService方法后执行如下回调，当你发布一个服务和任何一个相关特征的描述到GATI数据库的时候执行
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        DispatchQueue.main.async {
            SLLog.debug("准备广告")
            self.peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [self.service]])
        }
    }
    
    // 开始向外广播数据  当startAdvertising被执行的时候调用这个代理方法
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard error == nil else {
            return;
        }
        DispatchQueue.main.async {
            SLLog.debug("开始广告")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        DispatchQueue.main.async {
            SLLog.debug("有设备定阅特征")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        DispatchQueue.main.async {
            SLLog.debug("取消定阅特征")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        DispatchQueue.main.async {
            SLLog.debug("didReceiveRead")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        DispatchQueue.main.async {
            let application = UIApplication.shared
            if application.applicationState == .background {
                let appdelegate = application.delegate as! AppDelegate
                appdelegate.backgroundRun()
            }
            for item in requests {
                peripheral.respond(to: item, withResult: .success)
            }
        }
    }
}
