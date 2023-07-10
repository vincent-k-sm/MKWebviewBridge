//
//  MKWebViewController+WKDelegate.swift
//
        

import Foundation
import WebKit
import SafariServices

extension MKWebViewController: WKNavigationDelegate {
    // MARK: Open URL For new tab <a href='https://..' target='_blank'> (window.open)
    open func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        guard let url = navigationAction.request.url else { return nil }
        if navigationAction.targetFrame?.isMainFrame == nil {
            if UIApplication.shared.canOpenURL(url) {
                let safariViewController = SFSafariViewController(url: url)
                safariViewController.modalPresentationStyle = .fullScreen
                self.present(safariViewController, animated: true, completion: nil)
            }
        }

        return nil
    }
    
    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        MKWebKit.print("webViewDidStartLoad")
    }
    
    open func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        MKWebKit.print("didCommit")
    }
    
    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        MKWebKit.print("탐색 중 오류: \(error)")
    }
    
    open func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        MKWebKit.print("컨텐츠 로드 중 오류: \(error)")
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        var urlString = self.urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let localUrl = self.loadLocalFile()?.absoluteString {
            urlString = localUrl
        }
        
        MKWebKit.print("WebViewDidFinishLoad\n\(String(describing: urlString))")
        self.webView.getCookies(for: urlString, completion: { result in
            MKWebKit.print(result)
            
        })
        MKWebKit.print("Header: \(String(describing: self.webView.allheaderFields))")
    }

    @objc open func webView(_ webView: WKWebView, didChanged url: URL) {
        MKWebKit.print("url chagned to: \(url.absoluteString)")
    }
    
    @objc open func webView(_ webView: WKWebView, estimatedProgress to: Double) {
        MKWebKit.print("estimatedProgress: \(to)")
    }
    
    @available(*, deprecated, message: "Block Based KVO Violation / Prefer the new block based KVO API with keypaths when using Swift 3.2 or later")
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.url) {
            guard let url = self.webView.url else { return }
            if url.absoluteString != self.urlString {
                MKWebKit.print("url chagned to: \(url.absoluteString)")
            }
        }

        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            // When page load finishes. Should work on each page reload.
            if (self.webView.estimatedProgress == 1) {
                MKWebKit.print("estimatedProgress: \(self.webView.estimatedProgress)")
            }
        }

    }

    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        MKWebKit.print(navigationAction.request)
        if let url = navigationAction.request.url,
           let urlScheme = url.scheme {
            /// 허용된 Scheme 이며 앱 내 별도 처리 case
            if self.checkURLSchemeEnable(from: urlScheme) {
                MKWebKit.print("Need Parse \(url)")
                guard let component = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
                guard let host = component.host else { return }
                
                let queryItems = component.queryItems
                let queryResult = self.queryToDictionary(queryItems)
                self.handleDeeplink(host: host, query: queryResult)
                decisionHandler(.cancel)
                return
                
            }
            else {
                /// CustomScheme인 경우 처리
                if self.allowSchemes.contains(urlScheme) {
                    guard let url = navigationAction.request.url else { return }
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, completionHandler: { (success) in
                            MKWebKit.print("Settings opened: \(success)")
                        })
                    }
                    else {
                        MKWebKit.print("Cannot Open URL Scheme : \(url)")
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        
        decisionHandler(.allow)
    }
    
    private func checkURLSchemeEnable(from scheme: String) -> Bool {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [AnyObject] else {
            return false
        }
        var result = false
        urlTypes.forEach { url in
            if let urlTypeDictionary = url as? [String: AnyObject],
               let urlSchemes = urlTypeDictionary["CFBundleURLSchemes"] as? [String] {
                result = urlSchemes.filter({ $0 == scheme }).count >= 1
            }
        }
        return result
    }
}

extension MKWebViewController: WKUIDelegate {
    open func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        MKWebKit.print(message)
    }
    
    open func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        MKWebKit.print(message)
    }
    
    open func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        MKWebKit.print(prompt)
    }
    
}

extension MKWebViewController {
    /// query to dict
    private func queryToDictionary(_ array: [URLQueryItem]?) -> [String:String?] {
        guard array != nil else {
            return [:]
        }
        
        var dictionary = [String : String?]()
        for v in array! {
            dictionary.updateValue(v.value, forKey: v.name)
        }
        return dictionary
    }
}
