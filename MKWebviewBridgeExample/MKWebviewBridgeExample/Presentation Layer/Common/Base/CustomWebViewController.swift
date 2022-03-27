//
//  CustomWebViewController.swift
//


import Foundation
import UIKit
import MKWebview
import WebKit

class WrappedCustomWebViewController<U>: MKWebViewController, BaseViewControllerProtocol {
    typealias T = U
    
    var viewModel: T
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    convenience init() {
        fatalError("init() has not been implemented")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(viewModel: U) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        print("\(self) -- deinit")
    }
}

class CustomWebviewController<U>: WrappedCustomWebViewController<U> {
    
    
    convenience init() {
        fatalError("init() has not been implemented")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(viewModel: U) {
        super.init(viewModel: viewModel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    
    deinit {
        print("\(self) -- deinit")
    }
    
    
    // MARK: - WKNavigationDelegate
    override func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        super.webView(webView, didStartProvisionalNavigation: navigation)
        print("webViewDidStartLoad")
        DispatchQueue.main.async {
            ProgressView.shared.show()
        }
    }
    
    override func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        super.webView(webView, didCommit: navigation)
        print("didCommit")
    }
    
    override func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        super.webView(webView, didFail: navigation, withError: error)
        print( "탐색 중 오류: \(error)", self)
        DispatchQueue.main.async {
            ProgressView.shared.dismiss()
        }
    }
    
    override func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        super.webView(webView, didFailProvisionalNavigation: navigation, withError: error)
        print( "컨텐츠 로드 중 오류: \(error)", self)
        DispatchQueue.main.async {
            ProgressView.shared.dismiss()
        }
    }
    
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)
        print("webViewDidFinishLoad")
        
        DispatchQueue.main.async {
            ProgressView.shared.dismiss()
        }
    }
    
    // MARK: - WKUIDelegate
    override func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        super.webView(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onAlertInfo(message)
        }
        completionHandler()
    }
    
    override func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        super.webView(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.onAlertOkCancel(message) { action in
                switch action {
                    case .default:
                        completionHandler(true)

                    case .cancel:
                        completionHandler(false)
                    case .destructive:
                        completionHandler(true)
                    @unknown default:
                        completionHandler(false)
                }
            }
        }
        
    }
    
    open func handleDeeplink(path: String) {
        
    }
    
}

// MARK: - local alert
extension CustomWebviewController {
    func onAlertInfo(_ message: String) {
        let okAction = UIAlertAction(title: "확인", style: .destructive, handler: { _ in
            print("")
        })
        UIAlertController.showAlert(title: "", message: message, actions: [okAction])
    }
    
    func onAlertOkCancel(_ message: String, action: @escaping ((UIAlertAction.Style) -> Void)) {
        let okAction = UIAlertAction(title: "확인", style: .destructive, handler: { _ in
            action(.default)
        })
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: { _ in
            action(.cancel)
        })
        UIAlertController.showAlert(title: "", message: message, actions: [okAction, cancelAction])
        
    }
}

extension CustomWebviewController {
    private func setUI() {
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    }
    
}
