//
//  MKWebViewController.swift
//


import Foundation
import UIKit
import WebKit
import Combine

public protocol MKWebViewControllerDelegate: AnyObject {
    func deepLinkEvent(config: MKWebViewConfiguration)
}

open class MKWebViewController: UIViewController, UIGestureRecognizerDelegate {
    
    open weak var delegate: MKWebViewControllerDelegate?
    
    /// For Apply cookies when load
    /// - Parameters :
    /// - Usecase
    /*
     override func cookies() -> [HTTPCookie] {
         var cookies: [HTTPCookie] = []
         if let uuidCookie = HTTPCookie(properties: [.domain: "smbh.kr",
                                                     .path: "/",
                                                     .name: "CID",
                                                     .value: "\(UUID().uuidString)",
                                                     .secure: "TRUE"]) {
             cookies.append(uuidCookie)
         }
         return cookies
     }
     */
    open func cookies() -> [HTTPCookie] {
        return []
    }
    
    
    /// For Apply Headers when load
    /// - Parameters :
    /// - Usecase
    /*
     private var headerInfos: [String: String] = [
         "Content-Type": "application/json",
         "app-device-uuid": UUID().uuidString,
         "app-device-os-version": UIDevice.current.systemVersion,
         "app-version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
         "access-token": "access-token",
         "refresh-token": "refresh-token-value"
     ]
     ----
     override func headers() -> [String: String] {
         return self.headerInfos
     }
     */
    open func headers() -> [String: String] {
        return [:]
    }
    
    
    /// For Static URL Load
    /// - Parameters :
    /// - Usecase
    /*
     override func loadURLString() -> String? {
         return "https://smbh.kr/mk_bridge/sample"
     }
     */
    open func loadURLString() -> String? {
        return nil
    }
    
    /// For Static Local File Load
    /// - Parameters :
    /// - Usecase
    /*
     override func loadLocalFile() -> URL? {
        guard let url = Bundle.main.url(forResource: "sampleScheme", withExtension: "html") else { return nil }
        return url
     }
     */
    open func loadLocalFile() -> URL? {
        return nil
    }
    
    /// For Custom Scripts
    /// - Parameters :
    /// - Usecase
    /*
     override func onAddUserScript() -> String? {
         return """
            CustomScripts = {
                 showToast(s) {
                     window.webkit.messageHandlers.showToast.postMessage(s);
                 },
            }
        """
     /// It can Called `window.CustomScripts.showToast('msg';)` in JavaScript
     ----
     override func onAddPostMessage() {
         addPostMessageHandler("showToast") { (res) in
             
             if let res = res as? String {
                 Toast.shared.makeToast(res)
             }
         }
     }
     */
    open func onAddUserScript() -> String? {
        return nil
    }
    
    /// For Handle Scripts
    /// - Parameters :
    /// - Usecase
    open func onAddPostMessage() {
        //
    }
    
    open func addPostMessageHandler(_ key: String, result: @escaping ((Any?) -> Void)) {
        _callbacks[key] = result
        contentController.add(LeakAvoider(delegate: self, delegateReply: self), name: key)
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
    
    public var defaultSchemes = ["tel", "mailto", "sms", "facetime"]
    
    private(set) var urlString: String = "" {
        didSet {
            if let urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                guard let url = URL(string: urlString) else { return }
                self.webView.load(url: url, header: self.headers())
            }
        }
    }
    
    // MARK: - Local Properties
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
    
    var _callbacks = [String: ((Any?)->Void)]()
    var _replycallbacks = [String: ReplyCallBack]()
    
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
    
    public convenience init(config: MKWebViewConfiguration) {
        self.init()
        self.configuration = config
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.setupNavigationBar()
            self.setupStatusbar()
            self.setupWebView()
        }
        
        
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
//        self.webView.removeObserver(self, forKeyPath: "URL")
//        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
        
//        let ucc = webView.configuration.userContentController
//        ucc.removeAllUserScripts()
//        self._callbacks.keys.forEach {
//            ucc.removeScriptMessageHandler(forName: $0)
//        }
    }
}

// MARK: - [Public] Call Javascript
extension MKWebViewController {
    
    /*
     let value = "javascript:setToken('NEW_ACSESS_TOKEN');"
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

// MARK: - Local Methods
extension MKWebViewController {
    /// check Url string from all cases
    private func checkUrlString() -> URL? {
        var result: URL? = nil
        if let urlString = self.loadURLString()?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            guard let url = URL(string: urlString) else { return nil }
            result = url
        }
        if let url = URL(string: self.urlString) {
            result = url
        }
        if let url = self.loadLocalFile() {
            result = url
        }
        
        if let urlString = self.configuration?.urlString {
            guard let string = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
            guard let url = URL(string: string) else { return nil }
            result = url
        }
        
        return result
    }
    
    /// Genrate WKWebViewConfiguration
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
    struct Constants {
        static let statusbarTag = UUID().uuidString
    }
}

