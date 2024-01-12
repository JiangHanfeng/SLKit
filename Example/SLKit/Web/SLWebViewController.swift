//
//  SLWebViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/20.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import WebKit

class SLWebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
    
    private var titleString: String?
    private var url: String?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.colorWithHex(hexStr: "191919")
        label.text = self.titleString
        label.textAlignment = .center
        return label
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage.init(named: "icon_close"), for: .normal)
        btn.addTarget(self, action: #selector(back), for: .touchUpInside)
        return btn
    }()
    
    private lazy var partingLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.colorWithHex(hexStr: "#000000", alpha: 0.1)
        return line
    }()
    
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.selectionGranularity = .dynamic
        configuration.allowsInlineMediaPlayback = true
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        return WKWebView.init(frame: CGRect.zero, configuration: configuration)
    }()
    
    // 进度条
    private lazy var progressView: UIProgressView = {
        var progressView = UIProgressView()
        progressView.progressTintColor = UIColor.colorWithHex(hexStr: "#586CFF")
        progressView.trackTintColor = UIColor.clear
        return progressView
    }()
    
    private var navigationBarHidden: Bool?
    
    override func loadView() {
        super.loadView()
        let distanceTop = UIDevice.safeDistanceTop()
        self.navigationBarHidden = self.navigationController?.isNavigationBarHidden
        if let _ = self.navigationBarHidden {
            self.view.addSubview(self.webView)
            self.webView.snp.makeConstraints { make in
                make.top.bottom.left.right.equalTo(0)
            }
            
            let navigationBarHeight: CGFloat = 44
            self.view.addSubview(self.progressView)
            self.progressView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(distanceTop + navigationBarHeight)
                make.height.equalTo(5.0);
            }
        } else {
            self.view.addSubview(self.titleLabel)
            self.titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(distanceTop + 20)
            }
            
            self.view.addSubview(self.backBtn)
            self.backBtn.snp.makeConstraints { make in
                make.centerY.equalTo(self.titleLabel.snp.centerY)
                make.left.equalTo(20)
            }
            
            self.view.addSubview(self.partingLine)
            self.partingLine.snp.makeConstraints { make in
                make.top.equalTo(self.titleLabel.snp.bottom).offset(20)
                make.height.equalTo(1)
                make.left.right.equalTo(0)
            }
            
            self.view.addSubview(self.webView)
            self.webView.snp.makeConstraints { make in
                make.top.equalTo(self.partingLine.snp.bottom)
                make.bottom.left.right.equalTo(0)
            }
            
            self.view.addSubview(self.progressView)
            self.progressView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.partingLine.snp.bottom)
                make.height.equalTo(5.0);
            }
        }
    }
    
    init(_ title:String,_ url: String) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.titleString = title
        self.url = url
        self.navigationItem.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationBarHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationBarHidden {
            self.navigationController?.setNavigationBarHidden(navigationBarHidden, animated: true)
        }
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor =  UIColor.colorWithHex(hexStr: "#f7f7f7", alpha: 1)
        guard let urlStr = self.url else {
            return
        }
        if urlStr.hasPrefix("http") {
            guard let url = URL(string: urlStr) else {
                return
            }
            self.webView.load(URLRequest(url: url))
        } else {
            let url = URL.init(fileURLWithPath:urlStr)
            self.webView.load(URLRequest(url: url))
        }
    }
    
    @objc
    func back(){
        if let navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            
            self.progressView.alpha = 1.0
            self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            
            //进度条的值最大为1.0
            if(self.webView.estimatedProgress >= 1.0) {
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: { () -> Void in
                    self.progressView.alpha = 0.0
                }, completion: { (finished:Bool) -> Void in
                    self.progressView.progress = 0
                })
            }
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {    }
    
    // 加载完毕以后执行，自适应屏幕宽度，有的屏幕不自适应，需要自适应屏幕宽度
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webView.evaluateJavaScript("""
            
            var oMeta = document.createElement('meta');
            
            oMeta.content = 'width=device-width, initial-scale=1, user-scalable=0';
            
            oMeta.name = 'viewport';
            
            document.getElementsByTagName('head')[0].appendChild(oMeta);
            
            """,completionHandler: nil)
        
    }
    
    // 处理网页加载失败
    
    private func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        self.progressView.progress = 0
    }
    
    //处理网页加载完成
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.progressView.progress = 0
    }
    
}
