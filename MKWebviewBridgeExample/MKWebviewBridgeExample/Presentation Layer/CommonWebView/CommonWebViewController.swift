//
//  CommonWebViewController.swift
//

import MKUtils
import MKWebview
import UIKit
import WebKit

public struct CommonWebViewConfiguration {
    public var urlString: String = ""
    
    public init(urlString: String) {
        self.urlString = urlString
    }
}

open class CommonWebViewController: MKWebViewController {
    
    var configure: CommonWebViewConfiguration!
    
    private var defaultHeaderInfos: [String: String] = [
        "Content-Type": "application/json",
        "app-device-uuid": UUID().uuidString,
        "app-device-os-version": UIDevice.current.systemVersion,
        "app-device-device-manufacturer": "apple",
        "app-version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        "access-token": "\(UUID().uuidString)",
        "refresh-token": "refresh-token-value"
    ]
        
    open func customHeaders() -> [String: String] {
        return [:]
    }
    
    open override func headers() -> [String: String] {
        for (key, value) in self.customHeaders() {
            self.defaultHeaderInfos[key] = value
        }
        return self.defaultHeaderInfos
    }
    
    open override func cookies() -> [HTTPCookie] {
        var cookies: [HTTPCookie] = []
        
        if let uuidCookie = HTTPCookie(
            properties: [
                .domain: "kakao.com",
                .path: "/",
                .name: "TEST_CID",
                .value: "\(UUID().uuidString)",
                .secure: false
            ]
        ) {
            cookies.append(uuidCookie)
        }
        
        return cookies
    }
    
    open override func onAddUserScript() -> String? {
        return """
            CustomScripts = {
                 showToast(s) {
                     window.webkit.messageHandlers.showToast.postMessage(s);
                 },
            }
        """
    }
    
    open override func onAddPostMessage() {
        super.onAddPostMessage()
        if #available(iOS 14.0, *) {
            addPostMessageReplyHandler(JavaScriptsHandlers.getStorage, result: { result, handler in
                if let result = result as? String {
                    Debug.print(result)
                }
//                let stringValue: String = UserDefaultStore.webviewStorage("").data
                let stringValue: String = UserDefaults.standard.string(forKey: "webviewStorage") ?? ""
                handler(stringValue, nil)
                
            })
        }
        
        addPostMessageHandler(JavaScriptsHandlers.setStorage) { (res) in
            if let res = res as? String {
//                UserDefaultStore<String>.webviewStorage(res).save()
                UserDefaults.standard.set(res, forKey: "webviewStorage")
                Debug.print(res)
            }
        }
                
        addPostMessageHandler(JavaScriptsHandlers.getToken) { (_) in
            let value: [String: Any] = ["token": UUID().uuidString]
            self.callJavaScript(script: .setToken, value: value)
        }
    }
    
    lazy var topView: UIView = {
        let v = UIView()
        v.backgroundColor = .red
        let titleLabel = UILabel()
        titleLabel.text = "navview"
        titleLabel.textColor = .black
        v.addSubview(titleLabel)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: v.leftAnchor, constant: 0),
            titleLabel.rightAnchor.constraint(equalTo: v.rightAnchor, constant: 0),
            titleLabel.topAnchor.constraint(equalTo: v.topAnchor, constant: 0),
            titleLabel.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: 0)
        ])
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    open override func topContentView() -> UIView? {
        return self.topView
    }
    
#if DEBUG
    open override func loadLocalFile() -> URL? {
        guard let url = Bundle.main.url(forResource: "SampleScheme", withExtension: "html") else { return nil }
        return url
    }
#endif
    
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        self.setupUI()
//    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(config: CommonWebViewConfiguration) {
//        DKTWebKit.enableDebug = true
        self.configure = config
        super.init(nibName: nil, bundle: nil)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.urlString = self.configure.urlString
        self.setupLayout()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    open override func handleDeeplink(host: String, query: [String: String?]) {
        enum SchemeTypes: String {
            case webview = "webview"
            case close = "close-webview"
            case reload = "reload-webview"
            case unknown = ""
        }
    
        let scheme: SchemeTypes = SchemeTypes(rawValue: host) ?? .unknown
        Debug.print(scheme, query)
        switch scheme {
            case .webview:
                
                if let url = query["url"] as? String {
                    let vc = CommonWebViewController(config: .init(urlString: url))
                    self.navigationController?.pushViewController(vc, animated: true)
                }

            case .close:
                self.navigationController?.popViewController(animated: true)
                
            case .reload:
                self.reloadWebview()
                
            case .unknown:
                break
        }
    }
    
    deinit {
        Debug.print("")
    }
}

public extension CommonWebViewController {
    func callJavaScript(script: JavaScripts, value: [String: Any]) {
        self.evaluateJavascript(script, value: value, result: { response in
            switch response {
                case let .success(data):
                    Debug.print("\(String(describing: data))")
                    
                case let .failure(error):
                    Debug.print(error.localizedDescription)
            }
            
        })
    }
}

extension CommonWebViewController {
    private func setupUI() {
        self.view.backgroundColor = .white
    }
    
    private func setupLayout() {
        let guide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.topView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            self.topView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            self.topView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 0),
            self.topView.heightAnchor.constraint(equalToConstant: 56)
        ])
        
    }
}

extension CommonWebViewController {
    
    open override func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        super.webView(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onAlertInfo(message)
            completionHandler()
        }
        
    }
    
    open override func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
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
}

extension CommonWebViewController {
    private func onAlertInfo(_ message: String) {
        let okAction = UIAlertAction(title: "확인", style: .destructive, handler: { _ in
            Debug.print("")
        })
        
        let alert: UIAlertController = .init(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(okAction)
        self.navigationController?.present(alert, animated: true)
    }
    
    private func onAlertOkCancel(_ message: String, action: @escaping ((UIAlertAction.Style) -> Void)) {
        let okAction = UIAlertAction(title: "확인", style: .destructive, handler: { _ in
            action(.default)
        })
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: { _ in
            action(.cancel)
        })
        
        let alert: UIAlertController = .init(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.navigationController?.present(alert, animated: true)
        
    }
}
