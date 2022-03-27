//
//  MKWebViewController+.swift
//


import Foundation
import UIKit

// MARK: - Webview Layout
extension MKWebViewController {
    func setupWebView() {
        let guide = self.view.safeAreaLayoutGuide
        
        self.view.addSubview(self.webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: self.navigationView.bottomAnchor, constant: 0).isActive = true
        webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: 0).isActive = true
        webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 0).isActive = true
        webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 0).isActive = true
        
        webView.allowsBackForwardNavigationGestures = true
        
        self.view.addSubview(self.bottomSafeAreaView)
        bottomSafeAreaView.translatesAutoresizingMaskIntoConstraints = false
        bottomSafeAreaView.topAnchor.constraint(equalTo: self.webView.bottomAnchor, constant: 0).isActive = true
        bottomSafeAreaView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        bottomSafeAreaView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 0).isActive = true
        bottomSafeAreaView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 0).isActive = true
    }
    
    func setupNavigationBar() {
        let guide = self.view.safeAreaLayoutGuide
        self.view.addSubview(navigationView)
        navigationView.translatesAutoresizingMaskIntoConstraints = false
    
        navigationView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        navigationView.heightAnchor.constraint(equalToConstant: 56.0).isActive = true
        navigationView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        navigationView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.centerXAnchor.constraint(equalTo: navigationView.centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: navigationView.centerYAnchor).isActive = true
        
        self.leftBarButton.translatesAutoresizingMaskIntoConstraints = false
        leftBarButton.topAnchor.constraint(equalTo: navigationView.topAnchor).isActive = true
        leftBarButton.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor).isActive = true
        leftBarButton.bottomAnchor.constraint(equalTo: navigationView.bottomAnchor).isActive = true
        leftBarButton.widthAnchor.constraint(equalTo: navigationView.heightAnchor).isActive = true
        
        
        self.rightBarButton.translatesAutoresizingMaskIntoConstraints = false
        rightBarButton.topAnchor.constraint(equalTo: navigationView.topAnchor).isActive = true
        rightBarButton.trailingAnchor.constraint(equalTo: navigationView.trailingAnchor).isActive = true
        rightBarButton.bottomAnchor.constraint(equalTo: navigationView.bottomAnchor).isActive = true
        rightBarButton.widthAnchor.constraint(equalTo: navigationView.heightAnchor).isActive = true
    
        self.updateNavigationBar(config: self.configuration)
    }
    
    func setupStatusbar() {
        let guide = self.view.safeAreaLayoutGuide
        self.view.addSubview(statusBarView)
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
    
        statusBarView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        statusBarView.bottomAnchor.constraint(equalTo: navigationView.topAnchor).isActive = true
        statusBarView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        statusBarView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        
    }
    
    func updateNavigationBar(config: MKWebViewConfiguration?) {
        guard let config = config else {
            self.navigationView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            self.navigationView.isHidden = true
            return
        }

        self.navigationView.isHidden = !config.navigationBarIsEnable
        let navViewHeight = config.navigationBarIsEnable ? 56.0 : 0.0
        self.navigationView.heightAnchor.constraint(equalToConstant: navViewHeight).isActive = true
        
        if let title = config.title {
            self.titleLabel.text = title
        }
        
        
        if let color = config.navigationColor {
            let backgroundColor = UIColor(hexString: color)
            self.navigationView.backgroundColor = backgroundColor
        }
        
        
        if let tColor = config.tintColor {
            let tintColor = UIColor(hexString: tColor)
            self.leftBarButton.tintColor = tintColor
            self.rightBarButton.tintColor = tintColor
            self.titleLabel.textColor = tintColor
        }
        
        
        if let sColor = config.statusBarColor {
            let statusBarColor = UIColor(hexString: sColor)
            self.setStatusBarColor(color: statusBarColor)
        }
        else {
            self.setStatusBarColor(color: .white)
        }
        
        if let leftButton = config.leftBtn {
            self.leftBarButton.isHidden = !leftButton
        }
        
        if let rightButton = config.rightBtn {
            self.rightBarButton.isHidden = !rightButton
        }

    }
    
    private func setStatusBarColor(color: UIColor) {
        
        self.statusBarView.backgroundColor = color
    }
    
    @objc open func leftBarButtonTapped() {
        if self.webView.canGoBack {
            self.webView.goBack()
        }
        else {
            self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @objc open func rightBarButtonTapped() {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    

}
