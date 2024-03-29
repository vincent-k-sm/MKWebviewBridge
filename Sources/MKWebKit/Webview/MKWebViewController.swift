//
//  MKWebViewController.swift
//
        

import Foundation
import UIKit
import WebKit

public protocol ScriptInterface: RawRepresentable where RawValue == String { }

public typealias ReplyCallBack = (
    _ body: Any?,
    _ handler: @escaping (Any?, String?) -> Void
) -> Void

open class MKWebViewController: UIViewController, UIGestureRecognizerDelegate {
    
    /// For Apply cookies when load
    /// - Parameters :
    /// - Usecase
    /*
     override func cookies() -> [HTTPCookie] {
         var cookies: [HTTPCookie] = []
         if let uuidCookie = HTTPCookie(
             properties: [
                 .domain: "ko.kr",
                 .path: "/",
                 .name: "CID",
                 .value: "\(UUID().uuidString)",
                 .secure: false
             ]
         ) {
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
    
    /// Top Content View
    /// - Returns:
    ///   - view : Content View for Top Area
    ///   - Height : Content Height for Top Area
    open func topContentView() -> UIView? {
        return nil
    }
    
    /// Bottom Content View
    /// - Returns:
    ///   - view : Content View for Top Area
    open func bottomContentView() -> UIView? {
        return nil
    }
    
    /// For Regist Handle Scripts
    /// - Usecase
    open func onAddPostMessage() {
        //
    }
    
    open func addPostMessageHandler(_ key: some ScriptInterface, result: @escaping ((Any?) -> Void)) {
        _callbacks[key.rawValue] = result
        MKWebKit.print("handler \(key.rawValue) is registered")
        self.contentController.add(
            LeakAvoider(delegate: self, delegateReply: nil),
            name: key.rawValue
        )
    }
    /// iOS 14 이상 부터 javascript 통신 간 promise를 활용할 수 있습니다
    /// - Parameters:
    ///   - key: messageHandler 의 key
    ///   - handler: ReplyHandler Call back
    ///   - result: 결과처리
    ///   - UseCase
    /*
     --- javaScript ---
     var promise = window.webkit.messageHandlers.testWithPromise.postMessage( inputInfo );
     promise.then(
         function(result) {
             console.log(result); // "Stuff worked!"
             successFunc( result )
         },
         function(err) {
             console.log(err); // Error: "It broke"
             errorFunc( err )
         }
     );
     --- override func onAddPostMessage() ---
     if #available(iOS 14.0, *) {
        let promiseResult: ReplyHandler = ("Return Data", nil)
        addPostMessageReplyHandler("testWithPromise", handler: promiseResult, result: { result in
            print("Called")
        })
     }
     */
    @available(iOS 14.0, *)
    public func addPostMessageReplyHandler(_ key: some ScriptInterface, result: @escaping ReplyCallBack) {
//        let v: ReplyCallBack = (handler, result)
        _replycallbacks[key.rawValue] = result
        MKWebKit.print("for promise reply handler \(key.rawValue) is registered")
        
        self.contentController.addScriptMessageHandler(
            LeakAvoider(delegate: nil, delegateReply: self),
            contentWorld: .page,
            name: key.rawValue
        )
    }
    
    public func reloadWebview() {
        let configuration = WebkitManager.shared.configuration
        configuration.userContentController.removeAllUserScripts()
        
        if let userScript = self.onAddUserScript() {
            MKWebKit.print(userScript)
            let s = WKUserScript(
                source: userScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            configuration.userContentController.addUserScript(s)
        }
        
        self.contentController = configuration.userContentController
        self.webView.setCookies(cookies: self.cookies(), completion: { [weak self] in
            guard let self = self else { return }
            guard let url = self.checkUrlString() else { return }
            self.webView.load(url: url, header: self.headers())
        })
    }
    
    // MARK: "tel", "mailto", "sms", "facetime"
    ///  https://medium.com/@contact.jmeyers/complete-list-of-ios-url-schemes-for-apple-apps-and-services-always-updated-800c64f450f
    open var allowSchemes: [String] {
        return ["tel", "telprompt", "message", "mailto", "facetime", "sms", "shareddocuments", "app-settings"]
    }
    
    private(set) var _urlString: String = "" {
        didSet {
            self.reloadWebview()
        }
    }
    
    open var urlString: String {
        return self._urlString
    }
    
    public func setupURL(urlString: String, withEncoding: Bool) {
        if withEncoding {
            // % 엔코딩 된 문자열이 넘어오는 경우 다시 한 번 인코딩 될 수 있음
            let encodedValue: String = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString
            let expectURLString: String = encodedValue.replacingOccurrences(of: "%25", with: "%")
            self._urlString = expectURLString
        }
        else {
            self._urlString = urlString
        }
    }
    
    // MARK: - Local Properties
    
    var _callbacks = [String: ((Any?)->Void)]()
    var _replycallbacks = [String: ReplyCallBack]()
    
    var contentController: WKUserContentController!
    
    lazy open var webView: MKWebView = {

        let configuration = self.makeConfiguration()
        
        let v = MKWebView(frame: .zero, configuration: configuration)
        v.navigationDelegate = self
        v.uiDelegate = self
        
        /// Set Cookies
        v.setCookies(cookies: self.cookies(), completion: { [weak self] in
            guard let self = self else { return }
            guard let url = self.checkUrlString() else { return }
            v.load(url: url, header: self.headers())
        })

        v.allowsBackForwardNavigationGestures = true
        return v
    }()
    
    private var progressObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.startObserveWebview()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.stopObserveWebview()
    }
    
    open func handleDeeplink(host: String, query: [String: String?]) {
        
    }
    
    deinit {
        MKWebKit.print("")
    }
}

// MARK: - [Public] Call Javascript
extension MKWebViewController {
    
    /*
     Step 1.
     enum JavaScripts: String, ScriptInterface {
         case newAccessToken = "NEW_ACSESS_TOKEN"
         case setToken = "ACSESS_TOKEN"
         
     }

     --------------------------------------------------------------------
     Step 2.
     self.evaluateJavascript(script, value: value, result: { response in
         switch response {
             case let .success(data):
                 Debug.print("\(data)")
                 
             case let .failure(error):
                 Debug.print(error.localizedDescription)
         }
         
     })
     */
    public func evaluateJavascript(
        _ function: some ScriptInterface,
        value: [String: Any],
        result: EvaluateScriptResult
    ) {
        let dict = value
        if let data = try? JSONSerialization.data(withJSONObject: dict, options:[]) {
            let value = String(data: data, encoding: .utf8)
            var json = value!.replacingOccurrences(of: "\"", with: "\\\"")
            json = json.replacingOccurrences(of: "\'", with: "\\\'")
            let script = "javascript:\(function.rawValue)('\(json)')"
            self.evaluateJavascript(script, result: result)
        }
        
    }
    
    public func evaluateJavascript(
        _ function: some ScriptInterface,
        value: String,
        result: EvaluateScriptResult
    ) {
        let script = "javascript:\(function.rawValue)('\(value)')"
        self.evaluateJavascript(script, result: result)
        
    }
    
    /*
     let value = "javascript:setToken('NEW_ACSESS_TOKEN');"
     self.evaluateJavascript(value) { (result, _ ) in
         Debug.print(result)
     }
     */
    public func evaluateJavascript(
        _ function: String,
        result: EvaluateScriptResult
    ) {
        self.webView.evaluateJavascript(function, result: result)
    }
}

// MARK: - Local Methods
extension MKWebViewController {
    /// check Url string from all cases
    private func checkUrlString() -> URL? {
        var result: URL? = nil
        
        if let url = self.loadLocalFile() {
            result = url
        }
        
        if !self.urlString.isEmpty {
            if let url = URL(string: self.urlString) {
                result = url
            }
        }
                
        return result
    }
    
    /// Generate WKWebViewConfiguration
    private func makeConfiguration() -> WKWebViewConfiguration {
        
        let configuration = WebkitManager.shared.configuration
        /// Set Script
        configuration.userContentController = WKUserContentController()
        
        if let userScript = self.onAddUserScript() {
            MKWebKit.print(userScript)
            let script = WKUserScript(
                source: userScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            configuration.userContentController.addUserScript(script)

        }
        self.contentController = configuration.userContentController
        self.onAddPostMessage()
        return configuration
    }
    
}

extension MKWebViewController {
    private func setupUI() {
        self.view.backgroundColor = .clear
        if let topContentView = self.topContentView() {
            self.view.addSubview(topContentView)
        }
        
        self.view.addSubview(self.webView)
        self.updateLayout()
    }
    
    private func updateLayout() {
        let guide = self.view.safeAreaLayoutGuide
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 0),
            webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 0)
        ])
        
        if let topContentView = self.topContentView() {
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: topContentView.bottomAnchor, constant: 0)
            ])
            
        }
        else {
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 0)
            ])
        }
        
        if let bottomContentView = self.bottomContentView() {
            NSLayoutConstraint.activate([
                webView.bottomAnchor.constraint(equalTo: bottomContentView.topAnchor, constant: 0)
            ])
            
        }
        else {
            NSLayoutConstraint.activate([
                webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: 0)
            ])
        }
      
    }
}

// MARK: Observe
extension MKWebViewController {
    private func startObserveWebview() {
        self.urlObserver = self.webView.observe(\.url, options: .new, changeHandler: { [weak self] (v, _) in
            MKWebKit.print(v.url?.absoluteString ?? "")
            guard let self = self else { return }
            if let url: URL = v.url {
                self.webView(self.webView, didChanged: url)
            }
        })
        
        
        self.progressObserver = self.webView.observe(\.estimatedProgress, options: .new, changeHandler: { [weak self] (_, change) in
            guard let self = self else { return }
            if let value = change.newValue {
                self.webView(self.webView, estimatedProgress: value)
            }
            
        })
    }
    
    private func stopObserveWebview() {
        self.urlObserver = nil
        self.progressObserver = nil
    }
}
