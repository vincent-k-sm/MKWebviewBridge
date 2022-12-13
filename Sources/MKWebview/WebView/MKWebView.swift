//
//  MKWebView.swift
//


import Foundation
import UIKit
import WebKit

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
        DispatchQueue.main.async {
            WebkitManager.shared.setHeaders(headers: header, completion: { finish in
                SystemUtils.shared.print(finish.description, self)
                
                var request = URLRequest(url: url)
                header.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
                WebkitManager.shared.headers.forEach{ request.setValue($0.value, forHTTPHeaderField: $0.key) }
                self.urlRequest = request
                self.load(request)
                
                SystemUtils.shared.print("start Load", self)
                
                self.load(request)
            })
        }
        
    }
    

    public func setCookies(cookies: [HTTPCookie] = [], completion: @escaping (WKWebViewConfiguration) -> Void) {
        WebkitManager.shared.setCookies(cookies: cookies, completion: { [weak self] config in
            guard self != nil else { return }
            completion(config)
        })
    }
    
    public func getCookies(for domain: String? = nil, completion: @escaping ([String : Any])->())  {
        WebkitManager.shared.getCookies(for: domain, completion: { [weak self] (result) in
            guard self != nil else { return }
            completion(result)
        })
    }

}

