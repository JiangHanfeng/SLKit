//
//  SLSendFileSelectDeviceViewController.swift
//  FreeStyle
//
//  Created by shenjianfei on 2023/6/14.
//

import UIKit

private let cellkey = "selectDeviceCell"

class SLSendFileSelectDeviceViewController: SLBaseViewController {
    
    private var devices:[String:[SLDeviceModel]] = [:];
    private var pairDevice: SLPCDeviceModel?
    private var currentDevice: SLPCDeviceModel?
    private var files:[SLFileModel] = []
    private var checkFiles = false
    var sources:[String] = []
    var sharedUrlOpenInPlace: URL?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = .clear
        label.font = UIFont.font(17,.medium)
        label.textColor = UIColor.colorWithHex(hexStr: "191919")
        label.text = NSLocalizedString("SLSendFileSelectDeviceTitle", comment: "")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage.init(named: "off_icon"), for: .normal)
        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
        return btn
    }()
    
    private lazy var partingLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.colorWithHex(hexStr: "#000000", alpha: 0.1)
        return line
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(SLDeviceTableViewCell.self, forCellReuseIdentifier: cellkey)
        return tableView
    }()
    
    init(_ files:[SLFileModel], checkFiles: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.files = files
        self.checkFiles = checkFiles
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        let distanceTop = UIDevice.safeDistanceTop()
        
        self.view.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(distanceTop + 20)
        }
        
        self.view.addSubview(self.backBtn)
        self.backBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel.snp.centerY)
            make.right.equalTo(-20)
        }
        
        self.view.addSubview(self.partingLine)
        self.partingLine.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(20)
            make.height.equalTo(1)
            make.left.right.equalTo(0)
        }
        
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(self.partingLine.snp.bottom)
            make.bottom.left.right.equalTo(0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateDevicesList), name: UpdateDeviceList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateParingDevice), name: UpdatePariedDevice, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentDevice), name: UpdateConnetedDevice, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pariedDeviceSuccess), name: PariedDeviceSuccess, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.updateDevicesList()
        self.updateCurrentDevice()
    }
    
    @objc
    func updateDevicesList(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let nvc = appDelegate.window?.rootViewController as? UINavigationController,
              let vc = nvc.viewControllers.first as? SLHomepageViewController else {
            return
        }
        self.devices = vc.devices
        self.tableView.reloadData()
    }
    
    @objc
    func updateCurrentDevice() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let nvc = appDelegate.window?.rootViewController as? UINavigationController,
              let vc = nvc.viewControllers.first as? SLHomepageViewController else {
            return
        }
        self.currentDevice = vc.currentDevice
        self.tableView.reloadData()
    }
    
    @objc
    func updateParingDevice(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let nvc = appDelegate.window?.rootViewController as? UINavigationController,
              let vc = nvc.viewControllers.first as? SLHomepageViewController else {
            return
        }
        self.pairDevice = vc.pairDevice
        self.tableView.reloadData()
    }
    
    @objc
    func pariedDeviceSuccess(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let nvc = appDelegate.window?.rootViewController as? UINavigationController,
              let vc = nvc.viewControllers.first as? SLHomepageViewController else {
            return
        }
        guard let dev = vc.pairDevice else{
            return
        }
        SLConnectManager.share().sendFile(withDevice: dev, files:self.files) { taskId, allFiles in }
    }
    
    @objc
    func back(){
        self.dismiss(animated: true)
    }
    
    func connectingDevice(_ dev :SLDeviceModel){
        if SLConnectManager.share().isConnectedWifi() {
            if dev.isPaired {
                if self.currentDevice?.isSendFile() ?? false {
                    SLConnectManager.share().cancelFiles(withTaskId: self.currentDevice?.sendTaskId ?? "")
                } else {
                    _ = self.files.map({ file in
                        SLConnectManager.share().prepareSendFileModel(with:file)
                        return true
                    })
                    SLConnectManager.share().sendFile(withDevice: dev, files:self.files) { taskId, allFiles in }
                }
            } else {
                if let cDev = self.pairDevice {
                    if cDev.mac == dev.mac {
                        SLConnectManager.share().cancelPairDevice(cDev) { _ in }
                    } else {
                        SLConnectManager.share().cancelPairDevice(cDev) { _ in
                            SLConnectManager.share().pairDevice(dev)
                        }
                    }
                } else {
                    SLConnectManager.share().pairDevice(dev)
                }
            }
        } else {
            guard let appdelaget = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            appdelaget.toast(NSLocalizedString("SLErrorNotConnectedWifiHintString", comment:""))
        }
    }
}

private let row_count:Int = 3
extension SLSendFileSelectDeviceViewController : UITableViewDelegate,UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let pariedDevices = self.devices[pariedDeviceKey], pariedDevices.count != 0 {
                return pariedDevices.count%row_count == 0 ?  pariedDevices.count/row_count : pariedDevices.count/row_count+1
            } else if let normalDevices = self.devices[normalDeviceKey], normalDevices.count != 0 {
                return normalDevices.count%row_count == 0 ?  normalDevices.count/row_count : normalDevices.count/row_count+1
            }
        } else if section == 1 {
            if let normalDevices = self.devices[normalDeviceKey], normalDevices.count != 0 {
                return normalDevices.count%row_count == 0 ?  normalDevices.count/row_count : normalDevices.count/row_count+1
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellkey, for: indexPath) as! SLDeviceTableViewCell
        
        var showDevices: [SLDeviceModel] = []
        if indexPath.section == 0 {
            if let pariedDevices = self.devices[pariedDeviceKey], pariedDevices.count != 0 {
                showDevices = pariedDevices
            } else if let normalDevices = self.devices[normalDeviceKey], normalDevices.count != 0 {
                showDevices = normalDevices
            }
        } else if indexPath.section == 1 {
            if let normalDevices = self.devices[normalDeviceKey], normalDevices.count != 0 {
                showDevices = normalDevices
            }
        }
        
        if indexPath.row * row_count < showDevices.count {
            let dev = showDevices[indexPath.row * row_count]
            var status: SLPCDeviceModelStatusType = .normal
            if dev.isPaired {
                if let cDev = self.currentDevice,
                   cDev.mac == dev.mac {
                    status = self.currentDevice?.status() ?? .normal
                }
            } else {
                if let pDev = self.pairDevice,
                   pDev.mac == dev.mac {
                    status = self.pairDevice?.status() ?? .normal
                }
            }
            cell.loadDevice1(status,dev)
            if status == .sendFile {
                cell.sendProgress1(self.currentDevice?.sendProgress ?? 0)
            }
        } else {
            cell.loadDevice1(.normal, nil)
        }
        
        if (indexPath.row * row_count + 1) < showDevices.count {
            let dev = showDevices[indexPath.row * row_count + 1]
            var status: SLPCDeviceModelStatusType = .normal
            if dev.isPaired {
                if let cDev = self.currentDevice,
                   cDev.mac == dev.mac {
                    status = self.currentDevice?.status() ?? .normal
                }
            } else {
                if let pDev = self.pairDevice,
                   pDev.mac == dev.mac {
                    status = self.pairDevice?.status() ?? .normal
                }
            }
            cell.loadDevice2(status,dev)
            if status == .sendFile {
                cell.sendProgress2(self.currentDevice?.sendProgress ?? 0)
            }
        } else {
            cell.loadDevice2(.normal, nil)
        }
        
        if (indexPath.row * row_count + 2) < showDevices.count {
            let dev = showDevices[indexPath.row * row_count + 2]
            var status: SLPCDeviceModelStatusType = .normal
            if dev.isPaired {
                if let cDev = self.currentDevice,
                   cDev.mac == dev.mac {
                    status = self.currentDevice?.status() ?? .normal
                }
            } else {
                if let pDev = self.pairDevice,
                   pDev.mac == dev.mac {
                    status = self.pairDevice?.status() ?? .normal
                }
            }
            cell.loadDevice3(status,dev)
            if status == .sendFile {
                cell.sendProgress3(self.currentDevice?.sendProgress ?? 0)
            }
        } else {
            cell.loadDevice3(.normal, nil)
        }
        
        cell.selectItemBlock = { index in
            if self.checkFiles {
                var errorMsg: String?
                self.files.removeAll()
                if let sharedUrlOpenInPlace = self.sharedUrlOpenInPlace {
                    if sharedUrlOpenInPlace.startAccessingSecurityScopedResource() {
                        let _ = [sharedUrlOpenInPlace.path].map({ url in
                            if let model = SLConnectManager.share().createSendFileModel(withPath: url) {
                                self.files.append(model)
                            }
                        })
                    } else {
                        errorMsg = "没有权限读取该文件"
                    }
                } else if self.sources.isEmpty {
                    errorMsg = "找不到该文件"
                } else {
                    _ = self.sources.map({ url in
                        if let model = SLConnectManager.share().createSendFileModel(withPath: url) {
                            self.files.append(model)
                        }
                    })
                }
                guard self.files.count > 0 else {
                    errorMsg == nil ? errorMsg = "分享文件已被删除" : nil
                    (UIApplication.shared.delegate as? AppDelegate)?.toast(errorMsg!)
                    return
                }
            }
            if (indexPath.row * row_count + index) < showDevices.count {
                let dev = showDevices[indexPath.row * row_count + index]
                if self.currentDevice == nil || self.currentDevice?.mac == dev.mac {
                    self.connectingDevice(dev)
                } else {
                    guard let app = UIApplication.shared.delegate as? AppDelegate else {
                        return
                    }
                    app.alert(type: .warn,
                              title: NSLocalizedString("SLErrorFileTransferSwitchDeviceHintString", comment: ""),
                              noString: NSLocalizedString("SLYESTitle", comment: ""),
                              okString: NSLocalizedString("SLNOTitle", comment: ""),
                              descString: nil
                    ){[weak self] ret in
                        if ret {
                            SLConnectManager.share().discountScreenAndFileTransferDevice {
                                self?.connectingDevice(dev)
                            }
                        } else {
                            self?.back()
                        }
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        if (section == 1 || self.devices.count == 0) {
            
            let label = UILabel()
            label.text = NSLocalizedString("SLHomepageNotPariedDeviceString", comment: "")
            label.textColor = UIColor.colorWithHex(hexStr: "#666666")
            label.font = UIFont.font(12)
            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.equalTo(40)
                make.bottom.equalTo(-10)
            }
            
        } else {
            
            let label = UILabel()
            label.text = NSLocalizedString("SLSettingDeviceHintString", comment: "")
            label.textColor = UIColor.colorWithHex(hexStr: "#666666")
            label.font = UIFont.font(12)
            view.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.equalTo(40)
                make.bottom.equalTo(-10)
            }
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 || indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1  ? 135 : 105
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath){
        // 圆角弧度半径
        let cornerRadius: CGFloat = 16.0
        // 设置cell的背景色为透明，如果不设置这个的话，则原来的背景色不会被覆盖
        cell.backgroundColor = UIColor.clear
        // 创建一个shapeLayer
        let layer = CAShapeLayer()
        // 创建一个可变的图像Path句柄，该路径用于保存绘图信息
        let pathRef = CGMutablePath()
        // 获取cell的size
        // 第一个参数,是整个 cell 的 bounds, 第二个参数是距左右两端的距离,第三个参数是距上下两端的距离
        let bounds = cell.bounds.insetBy(dx: 20, dy: 0)
        
        // 这里要判断分组列表中的第一行，每组section的第一行，每组section的中间行
        if indexPath.row == 0 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            pathRef.addRoundedRect(in: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        }else if indexPath.row == 0{
            pathRef.move(to: CGPoint(x: bounds.minX, y: bounds.maxY), transform: .identity)
            pathRef.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.minY), tangent2End: CGPoint(x: bounds.midX, y: bounds.minY), radius: cornerRadius, transform: .identity)
            pathRef.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.minY), tangent2End: CGPoint(x: bounds.maxX, y: bounds.midY), radius: cornerRadius, transform: .identity)
            pathRef.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY), transform: .identity)
        }else if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section)-1) {
            pathRef.move(to: CGPoint(x: bounds.minX, y: bounds.minY), transform: .identity)
            pathRef.addArc(tangent1End: CGPoint(x: bounds.minX, y: bounds.maxY), tangent2End: CGPoint(x: bounds.midX, y: bounds.maxY), radius: cornerRadius, transform: .identity)
            pathRef.addArc(tangent1End: CGPoint(x: bounds.maxX, y: bounds.maxY), tangent2End: CGPoint(x: bounds.maxX, y: bounds.midY), radius: cornerRadius, transform: .identity)
            pathRef.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY), transform: .identity)
        } else {
            pathRef.move(to: CGPoint.init(x:bounds.minX, y: bounds.minY))
            pathRef.addLine(to: CGPoint.init(x: bounds.minX, y: bounds.maxY))
            pathRef.addLine(to: CGPoint.init(x: bounds.maxX, y: bounds.maxY))
            pathRef.addLine(to: CGPoint.init(x: bounds.maxX, y: bounds.minY))
            pathRef.closeSubpath()
        }
        // 把已经绘制好的可变图像路径赋值给图层，然后图层根据这图像path进行图像渲染render
        layer.path = pathRef;
        
        // 注意：但凡通过Quartz2D中带有creat/copy/retain方法创建出来的值都必须要释放
        //CFRelease(pathRef);
        
        //颜色修改
        layer.fillColor = UIColor.white.cgColor
        layer.strokeColor = UIColor.white.cgColor
        
        
        let testView = UIView(frame: bounds)
        testView.layer.insertSublayer(layer, at: 0)
        testView.backgroundColor = tableView.backgroundColor
        cell.backgroundView = testView
    }
}

