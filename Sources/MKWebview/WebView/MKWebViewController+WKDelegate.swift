//
//  MKWebViewController+WKDelegate.swift
//


import Foundation
import WebKit

extension MKWebViewController: WKNavigationDelegate{
    open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        SystemUtils.shared.print("webViewDidStartLoad", self)
    }
    
    open func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        SystemUtils.shared.print("didCommit", self)
    }
    
    open func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        SystemUtils.shared.print("탐색 중 오류: \(error)", self)
    }
    
    open func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        SystemUtils.shared.print("컨텐츠 로드 중 오류: \(error)", self)
    }
    
    open func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        var urlString = self.loadURLString()?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let localUrl = self.loadLocalFile()?.absoluteString {
            urlString = localUrl
        }
        
        SystemUtils.shared.print("WebViewDidFinishLoad\n\(String(describing: urlString))", self)
        self.webView.getCookies(for: urlString, completion: { [weak self] result in
            guard let self = self else { return }
            SystemUtils.shared.print(result, self)
            
        })
        
        SystemUtils.shared.print(self.webView.allheaderFields ?? "", self)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.url) {
            guard let url = self.webView.url else { return }
            if url.absoluteString != self.urlString {
                SystemUtils.shared.print("url chagned to: \(url.absoluteString)", self)
            }
        }

        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            // When page load finishes. Should work on each page reload.
            if (self.webView.estimatedProgress == 1) {
                SystemUtils.shared.print("estimatedProgress: \(self.webView.estimatedProgress)", self)
            }
        }

    }

    open func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        SystemUtils.shared.print(navigationAction.request, self)
        
        // Check whether WebView Native is linked
        if let url = navigationAction.request.url,
           let urlScheme = url.scheme {
            if self.checkURLSchemeEnable(from: urlScheme) {
                
                // Handle Deep link
                SystemUtils.shared.print("need parse deeplink \(url)", self)
                guard let component = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
                guard let host = component.host else { return }

                var configure = MKWebViewConfiguration()
                configure.host = host
                
                if let queryItems = component.queryItems {
                    let queryResult = self.queryToDictionary(queryItems)
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: queryResult, options: .prettyPrinted)
                        var result = try JSONDecoder().decode(MKWebViewConfiguration.self, from: jsonData)
                        SystemUtils.shared.print(result, self)
                        result.host = host
                        configure = result
                    }
                    catch {
                        SystemUtils.shared.print(error.localizedDescription, self)
                    }
                }
                
                self.delegate?.deepLinkEvent(config: configure)
                decisionHandler(.cancel)
                return
                
            }
            else {
                // handle Likes tel:, mailto ..
                if self.defaultSchemes.contains(urlScheme) {
                    guard let url = navigationAction.request.url else { return }
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, completionHandler: { (success) in
                            SystemUtils.shared.print("Settings opened: \(success)", self)
                        })
                    }
                    else {
                        SystemUtils.shared.print("Cannot Open URL Scheme : \(url)", self)
                    }
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
        SystemUtils.shared.print(message, self)
    }
    
    open func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        SystemUtils.shared.print(message, self)
    }
    
    open func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        SystemUtils.shared.print(prompt, self)
    }
    
    func showAlert(msg: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: nil, message: msg, preferredStyle: UIAlertController.Style.alert)
        
        actions.forEach {
            alertController.addAction($0)
        }
        self.present(alertController, animated: true, completion: nil)
    }
}

extension MKWebViewController {
    /// query to dict
    private func queryToDictionary(_ array: [URLQueryItem]?) -> [String:String?]{
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
