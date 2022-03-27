//
//  MKWebViewController.swift
//


import Foundation
import UIKit
import WebKit
import Combine

public typealias ReplyHandler = (result: Any?, error: String?)
public typealias ReplyCallBack = (handler: ReplyHandler, callBack: (Any?)->Void)

public protocol MKWebViewControllerDelegate: AnyObject {
    func deepLinkEvent(config: MKWebViewConfiguration)
}

open class MKWebViewController: UIViewController, UIGestureRecognizerDelegate {
    lazy var statusBarView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()
    
    public lazy var navigationView: UIView = {
        let v = UIView()
        v.addSubview(leftBarButton)
        v.addSubview(rightBarButton)
        v.addSubview(titleLabel)
        v.backgroundColor = .white
        return v
    }()
    
    public lazy var leftBarButton: UIButton = {
        let v = UIButton(type: .custom)
        let image = UIImage(named: "icn_arrow_left_gray", in: Bundle.module, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        v.setImage(image, for: .normal)
        v.addTarget(self, action: #selector(self.leftBarButtonTapped), for: .touchUpInside)
        v.isHidden = true
        v.tintColor = UIColor(hexString: "292F33")
        return v
    }()
    
    public lazy var rightBarButton: UIButton = {
        let v = UIButton(type: .custom)
        let image = UIImage(named: "icn_cross_gray", in: Bundle.module, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        v.setImage(image, for: .normal)
        v.addTarget(self, action: #selector(self.rightBarButtonTapped), for: .touchUpInside)
        v.tintColor = UIColor(hexString: "292F33")
        v.isHidden = true
        return v
    }()
    
    public lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.textColor = UIColor(hexString: "292F33")
        return v
    }()
    
    lazy var bottomSafeAreaView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()
    
    open var configuration: MKWebViewConfiguration? = nil {
        willSet {
            self.updateNavigationBar(config: newValue)
        }
    }
    
    open weak var delegate: MKWebViewControllerDelegate?
    
    private var _callbacks = [String: ((Any?)->Void)]()
    private var _replycallbacks = [String: ReplyCallBack]()
    
    open func cookies() -> [HTTPCookie] {
        return []
    }
    
    open func headers() -> [String: String] {
        return [:]
    }
    
    open func loadURLString() -> String? {
        return nil
    }
    
    open func loadLocalFile() -> URL? {
        return nil
    }
    
    public var urlString: String = "" {
        didSet {
            if let urlString = oldValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                guard let url = URL(string: urlString) else { return }
                self.webView.load(url: url, header: self.headers())
            }
        }
    }
    
    public var defaultScript = """

    """
    
    open func onAddUserScript() -> String? {
        return nil
    }
    
    var contentController: WKUserContentController!
    
    lazy open var webView: MKWebView = {

        let configuration = self.makeConfiguration()
        
        let v = MKWebView(frame: .zero, configuration: configuration)
        v.navigationDelegate = self
        v.uiDelegate = self
        
        v.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
        v.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
                
        /// Set Cookies
        v.setCookies(cookies: self.cookies(), completion: { [weak self] _ in
            guard let self = self else { return }
            guard let url = self.checkUrlString() else { return }
            v.load(url: url, header: self.headers())
        })

        return v
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        self.setupStatusbar()
        self.setupWebView()
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    deinit {
        self.webView.removeObserver(self, forKeyPath: "URL")
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
        
        let ucc = webView.configuration.userContentController
        ucc.removeAllUserScripts()
        self._callbacks.keys.forEach {
            ucc.removeScriptMessageHandler(forName: $0)
        }
    }
    
    open func onAddPostMessage() {
        //
    }
    
    open func addPostMessageHandler(_ key: String, result: @escaping ((Any?) -> Void)) {
        _callbacks[key] = result
        contentController.add(LeakAvoider(delegate: self, delegateReply: self), name: key)
    }
    
    @available(iOS 14.0, *)
    public func addPostMessageReplyHandler(_ key: String, handler: ReplyHandler, result: @escaping ((Any?) -> Void)) {
        let v: ReplyCallBack = (handler, result)
        _replycallbacks[key] = v
        
        contentController.addScriptMessageHandler(
            LeakAvoider(delegate: self, delegateReply: self),
            contentWorld: .page,
            name: key
        )
        
    }
    
    public func reloadWebview() {
        let configuration = WebkitManager.shared.configuration
        configuration.userContentController.removeAllUserScripts()
        
        if let userScript = onAddUserScript() {
            SystemUtils.shared.print(userScript, self)
            let s = WKUserScript(source: userScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            contentController.addUserScript(s)

        }
        
        self.webView.setCookies(cookies: self.cookies(), completion: { [weak self] _ in
            guard let self = self else { return }
            guard let url = self.checkUrlString() else { return }
            self.webView.load(url: url, header: self.headers())
            
        })
    }
}

extension MKWebViewController {
    private func setupWebView() {
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
    
    private func setupNavigationBar() {
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
    
    private func setupStatusbar() {
        let guide = self.view.safeAreaLayoutGuide
        self.view.addSubview(statusBarView)
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
    
        statusBarView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        statusBarView.bottomAnchor.constraint(equalTo: navigationView.topAnchor).isActive = true
        statusBarView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        statusBarView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        
    }
    
    private func updateNavigationBar(config: MKWebViewConfiguration?) {
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
    
    private func checkUrlString() -> URL? {
        var result: URL? = nil
        if let urlString = self.loadURLString()?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            guard let url = URL(string: urlString) else { return nil }
            result = url
        }
        else if let url = URL(string: self.urlString) {
            result = url
        }
        else if let url = self.loadLocalFile() {
            result = url
        }
        else if let urlString = self.configuration?.urlString {
            guard let string = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            guard let url = URL(string: string) else { return nil }
            result = url
        }
        return result
    }
}

extension MKWebViewController {
    struct Constants {
        static let statusbarTag = UUID().uuidString
    }
}

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
           let urlScheme = url.scheme,
           self.checkURLSchemeEnable(from: urlScheme) {
            // Handle Deep link
            SystemUtils.shared.print("need parse deeplink", self)
            
            if let component = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let host = component.host {
                
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
            }
            else {
                // handle Likes tel:, mailto ..
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, completionHandler: { (success) in
                        SystemUtils.shared.print("Settings opened: \(success)", self)
                    })
                }
            }
            
            
            decisionHandler(.cancel)
            return
        }
        
        if navigationAction.request.url?.scheme == "tel" {
            guard let url = navigationAction.request.url else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, completionHandler: { (success) in
                    SystemUtils.shared.print("Settings opened: \(success)", self)
                    return
                })
            }
            else {
                SystemUtils.shared.print("Cannot Open URL Scheme : \(url)", self)
            }
        }
        
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url,
               let host = url.host,
               let webViewHost = self.webView.url?.host
            {
                if host != webViewHost {
                    UIApplication.shared.open(url, completionHandler: { (success) in
                        SystemUtils.shared.print("Settings opened: \(success)", self)
                    })
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
        
        let okAction = UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            completionHandler()
        })
        
        self.showAlert(msg: message, actions: [okAction])
        
    }
    open func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        SystemUtils.shared.print(message, self)
        
        let okAction = UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            completionHandler(true)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        })
        self.showAlert(msg: message, actions: [okAction, cancelAction])

    }
    
    open func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        SystemUtils.shared.print(prompt, self)
            
//        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: UIAlertController.Style.alert)
//
//        alertController.addTextField { (textField) in
//            textField.text = defaultText
//        }
//
//        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
//            if let text = alertController.textFields?.first?.text {
//                completionHandler(text)
//            } else {
//                completionHandler(defaultText)
//            }
//
//        }))
//
//        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
//
//            completionHandler(nil)
//        }))
//
//        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(msg: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: nil, message: msg, preferredStyle: UIAlertController.Style.alert)
        
        actions.forEach {
            alertController.addAction($0)
        }
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - JavaScript Handler
extension MKWebViewController: WKScriptMessageHandler {
    open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        var bodyMsg = ""
        if let body = message.body as? String {
            bodyMsg = body
        }
        SystemUtils.shared.print("name: \(message.name), body: \(bodyMsg)", self)
        
        for (key, f) in _callbacks {
            if message.name == key {
                f(bodyMsg)
                break
            }
        }
    }
}

// MARK: - JavaScript Call back handler
@available(iOS 14.0, *)
extension MKWebViewController: WKScriptMessageHandlerWithReply {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        var bodyMsg = ""
        if let body = message.body as? String {
            bodyMsg = body
        }
        for (key, value) in _replycallbacks {
            if message.name == key {
                
                let v = value.handler
                replyHandler(v.result, v.error)
                value.callBack(bodyMsg)
                break
            }
        }
                
        SystemUtils.shared.print("name: \(message.name), body: \(bodyMsg)", self)
    }
}

// MARK: - Call Javascript
extension MKWebViewController {
    /*
     let value = "DispatchCustomEvent('districtOpenSubscribe');"
     self.evaluateJavascript(value) { (result, _ ) in
         Debug.print(result)
     }
     */
    public func evaluateJavascript(_ function: String, result: ((Bool, Any?) -> Void)?) {
        self.webView.evaluateJavaScript("\(function)") { (ret, error) in
            if let error = error {
                SystemUtils.shared.print(error, self)
                if let s = result {
                    s(false, nil)
                }
            }
            else {
                if let ret = ret {
                    SystemUtils.shared.print("\(ret)", self)
                    if let s = result {
                        s(true, ret)
                    }
                }
            }
        }
    }
}

extension MKWebViewController {
    private func makeConfiguration() -> WKWebViewConfiguration {
        
        let configuration = WebkitManager.shared.configuration

        /// Set Script
        self.contentController = WKUserContentController()
        if let userScript = onAddUserScript() {
            SystemUtils.shared.print(userScript, self)
            let s = WKUserScript(source: userScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            contentController.addUserScript(s)

        }
        onAddPostMessage()
        
        configuration.userContentController = contentController
        return configuration
    }
}


extension MKWebViewController {
    func queryToDictionary(_ array: [URLQueryItem]?) -> [String:String?]{
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

