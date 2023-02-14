//
//  NewCommonWebViewController.swift
//

import MKUtils
import UIKit
import WebKit

class NewCommonWebViewController: MKWebViewController {
    
    private var headerInfos: [String: String] = [
        "Content-Type": "application/json",
        "app-device-uuid": UUID().uuidString,
        "app-device-os-version": UIDevice.current.systemVersion,
        "app-device-device-manufacturer": "apple",
        "app-version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        "access-token": "\(UUID().uuidString)",
        "refresh-token": "refresh-token-value"
    ]
    
    override func headers() -> [String: String] {
        return self.headerInfos
    }
    
    override func cookies() -> [HTTPCookie] {
        var cookies: [HTTPCookie] = []
        
        if let uuidCookie = HTTPCookie(
            properties: [
                .domain: "kakao.com",
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
    
    override func onAddUserScript() -> String? {
        return """
            CustomScripts = {
                 showToast(s) {
                     window.webkit.messageHandlers.showToast.postMessage(s);
                 },
            }
        """
    }
    
    override func onAddPostMessage() {
        super.onAddPostMessage()
        
        if #available(iOS 14.0, *) {
            addPostMessageReplyHandler(JavaScriptsHandlers.testWithPromise, result: { result, handler in
                if let result = result as? String {
                    Debug.print(result)
                }
                
                handler("\(UUID().uuidString)", nil)
                
            })
        }
        
        addPostMessageHandler(JavaScriptsHandlers.showToast) { (res) in
            
            if let res = res as? String {
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
        return v
    }()
    
    override func topContentView() -> (view: UIView, height: CGFloat)? {
        return (topView, 65)
    }
    
    override func loadLocalFile() -> URL? {
        guard let url = Bundle.main.url(forResource: "sampleScheme", withExtension: "html") else { return nil }
        return url
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func handleDeeplink(host: String, query: [String: String?]) {
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
                let vc = NewCommonWebViewController()
                if let url = query["url"] as? String {
                    vc.urlString = url
                }
                self.navigationController?.pushViewController(vc, animated: true)
                
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

extension NewCommonWebViewController {
    override func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        super.webView(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert: UIAlertController = .init(
                title: nil,
                message: message,
                preferredStyle: .alert
            )
            let confirmAction: UIAlertAction = .init(
                title: "확인",
                style: .default
            ) { _ in
                completionHandler()
            }
            alert.addAction(confirmAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension NewCommonWebViewController {
    private func setupUI() {
        self.view.backgroundColor = .white
    }
}

extension NewCommonWebViewController {
    private func callJavaScript(script: JavaScripts, value: [String: Any]) {
        
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
