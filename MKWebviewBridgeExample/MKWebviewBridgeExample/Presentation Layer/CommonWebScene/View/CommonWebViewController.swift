// 
// CommonWebViewController.swift
// 

import UIKit
import MKWebview

class CommonWebViewController: CustomWebviewController<CommonWebViewModel> {
    
    private var headerInfos: [String: String] = [
        "Content-Type": "application/json",
        "app-device-uuid": UUID().uuidString,
        "app-device-os-version": UIDevice.current.systemVersion,
        "app-device-device-manufacturer": "apple",
        "app-version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        "access-token": "\(UUID().uuidString)",
        "refresh-token": "refresh-token-value"
    ]
    
    override func loadURLString() -> String? {
//        return "https://smbh.kr/mk_bridge/sample"
        return "https://www.smbh.kr/mk_bridge/sample2.html"
    }
    
    override func loadLocalFile() -> URL? {
        guard let url = Bundle.main.url(forResource: "sampleScheme", withExtension: "html") else { return nil }
        return url
    }
    
    override func headers() -> [String: String] {
        return self.headerInfos
    }
    
    override func cookies() -> [HTTPCookie] {
        var cookies: [HTTPCookie] = []
        
        if let uuidCookie = HTTPCookie(properties: [.domain: "smbh.kr",
                                                    .path: "/",
                                                    .name: "CID",
                                                    .value: "\(UUID().uuidString)",
                                                    .secure: false]) {
            cookies.append(uuidCookie)
        }
        
        return cookies
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.setUI()
        self.bindViewModel()
        self.viewModel.viewDidLoad()
        self.bindEvent()

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
        let promiseResult: ReplyHandler = ("\(UUID().uuidString)", nil)
        if #available(iOS 14.0, *) {
            addPostMessageReplyHandler("testWithPromise", handler: promiseResult, result: { result in
                print("Called")
            })
        }
        
        addPostMessageHandler("showToast") { (res) in
            
            if let res = res as? String {
                MKToast.makeToast(text: res)
            }
        }
        
        addPostMessageHandler("getToken") { (res) in
            let value: [String: Any] = ["token": UUID().uuidString]
            self.callJavaScript(script: "setToken", value: value)
        }
        
        addPostMessageHandler("logEvent") { (res) in
            
            if let res = res as? String {
                MKToast.makeToast(text: res)
            }
        }
    }
    

    deinit {
        print("\(Self.self) -- deinit")
    }
    
    
    override func handleDeeplink(path: String) {
        super.handleDeeplink(path: path)
        let action = DeepLinkTypes(rawValue: path) ?? .unknown
        print("called : \(action)")
    }
}

extension CommonWebViewController {
    private func setUI() {
        self.delegate = self
    }
}

extension CommonWebViewController {
    private func bindViewModel() {
        
    }
}

extension CommonWebViewController {
    private func bindEvent() {

    }
}

extension CommonWebViewController {
    private func callJavaScript(script: String, value: [String: Any]) {
        guard let json = value.toJsonString() else { return }
        let script = "javascript:\(script)('\(json)')"
        self.evaluateJavascript(script, result: nil)
    }
}


// MARK: - MKWebViewControllerDelegate
extension CommonWebViewController: MKWebViewControllerDelegate {

    func deepLinkEvent(config: MKWebViewConfiguration) {
        switch DeepLinkTypes(rawValue: config.host) ?? .none {
            case .reloadWebview:
                self.reloadWebview()
                
            case .closeWebview:
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
                
            case .webview:
                self.presentNewVC(config: config)
                
            default:
                self.handleDeeplink(path: config.host)
            
        }
    }
    
    func presentNewVC(config: MKWebViewConfiguration) {
        
        let viewModelInput = CommonWebViewModelInput(config: config)
        let viewModelAction = CommonWebViewModelAction()
        let tempViewModel = CommonWebViewModel(input: viewModelInput, actions: viewModelAction)
        let vc = CommonWebViewController(viewModel: tempViewModel)
        vc.configuration = config
        vc.hidesBottomBarWhenPushed = true

        self.navigationController?.pushViewController(vc, animated: true)
        if let removeStack = config.removeStack,
           removeStack,
           let navigationController = self.navigationController {
            let vcs = navigationController.viewControllers
            if vcs.count >= 3 {
                let stack = [vcs.first!, vcs.last!]
                self.navigationController?.viewControllers = stack
            }
            
        }
    }
    
}
