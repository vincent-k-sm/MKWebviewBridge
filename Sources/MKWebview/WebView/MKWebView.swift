//
//  MKWebView.swift
//
        
import UIKit
import WebKit

public typealias EvaluateScriptResult = ((Result<Any?, Error>) -> Void)?

open class MKWebView: WKWebView {
    public var urlRequest: URLRequest? = nil
    
    public var allheaderFields: [String: String]? {
        return self.urlRequest?.allHTTPHeaderFields
    }
    
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }
    
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    open func load(url: URL, header: [String: String]) {
        self.setupUserAgent()
        
        WebkitManager.shared.setHeaders(headers: header, completion: { finish in
            MKWebKit.print("Webview SetHeaders: \(finish.description)")
            
            var request = URLRequest(url: url)
//            header.forEach {
//                request.setValue($0.value, forHTTPHeaderField: $0.key)
//            }
            
            WebkitManager.shared.headers.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }
            
            self.urlRequest = request
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.load(request)
            }
            
            MKWebKit.print("Start Load Webview")
   
        })
        
    }
    
    private func setupUserAgent() {
        self.evaluateJavascript(Constants.userAgentKey, result: { result in
            var agent = ""
            switch result {
                case let .success(data):
                    agent = String(describing: data)

                case let .failure(error):
                    MKWebKit.print("empty customUserAgent", error.localizedDescription)
            }
            
            agent += " NATIVE_iOS"
            self.customUserAgent = agent
        })
    }
    public func setCookies(
        cookies: [HTTPCookie] = [],
        completion: @escaping () -> Void
    ) {
        WebkitManager.shared.setCookies(cookies: cookies, completion: {
            completion()
        })
    }
    
    public func getCookies(
        for domain: String? = nil,
        completion: @escaping ([String : Any])->()
    ) {
        WebkitManager.shared.getCookies(for: domain, completion: { (result) in
            completion(result)
        })
    }
    
    public func evaluateJavascript(
        _ function: String,
        result: EvaluateScriptResult
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.evaluateJavaScript("\(function)") { (ret, error) in
                if let error = error {
                    MKWebKit.print(error)
                    result?(.failure(error))
                    return
                }
                
                if let ret = ret {
                    MKWebKit.print("\(ret)")
                    result?(.success(ret))
                }
            }
        }
        
    }

}

extension MKWebView {
    struct Constants {
        static let userAgentKey = "navigator.userAgent"
    }
}
