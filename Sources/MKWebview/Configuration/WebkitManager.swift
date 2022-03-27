//
//  WebkitManager.swift
//


import Foundation
import WebKit

public final class WebkitManager {
    public static let shared = WebkitManager()
    var websiteDataStore = WKWebsiteDataStore.default() //
    
    public var configuration: WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.preferences = defaultPreferences
        configuration.processPool = defaultProcessPool
//        configuration.userContentController = defaultUserContentController
        return configuration
    }
    
    var defaultPreferences: WKPreferences {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = false
        return preferences
    }
    
    var defaultProcessPool: WKProcessPool = WKProcessPool()
    
//    var defaultUserContentController: WKUserContentController {
//        return WKUserContentController()
//    }
    
    public var headers: [String: String] = [:]
    
    /// Cookies from http cookie store.
    public var httpCookies: [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies ?? [HTTPCookie]()
    }

    /// Pass cookie to wkwebview.
    /// - Parameter completion: returns WKConfiguration.
    public func syncCookies(completion: @escaping (WKWebViewConfiguration) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.configuration.websiteDataStore = self.websiteDataStore

            let dispatchGroup = DispatchGroup()
            self.httpCookies.forEach {

                dispatchGroup.enter()
                self.websiteDataStore.httpCookieStore.setCookie($0) {
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                completion(self.configuration)
            })
        }
    }
    
    public func setHeaders(headers: [String:String], completion: @escaping (Bool) -> Void) {
        
        if headers.isEmpty {
            completion(true)
        }
        
        let dispatchGroup = DispatchGroup()
        DispatchQueue.main.async {
            headers.forEach { key, value in
                dispatchGroup.enter()
                self.headers[key] = value
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            completion(true)
        })
        
    }
    
    public func setCookies(cookies: [HTTPCookie] = [], completion: @escaping (WKWebViewConfiguration) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.configuration.websiteDataStore = self.websiteDataStore

            if cookies.isEmpty {
                completion(self.configuration)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            cookies.forEach {
                dispatchGroup.enter()
                self.websiteDataStore.httpCookieStore.setCookie($0) {
                    dispatchGroup.leave()
                }

            }
            dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                completion(self.configuration)
            })
        }
    }
    
    /// Clears all cookie.
    /// - Parameter completion: completion block.
    public func removeCookies(completion: @escaping() -> Void) {

        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.deleteWKcookie {
                for cookie in self.httpCookies {
                    SystemUtils.shared.print(cookie.value, self)
                }
                
                self.configuration.processPool = WKProcessPool()
                completion()
            }
        }
    }
    
    public func getCookies(for domain: String? = nil, completion: @escaping ([String : Any])->())  {
        var cookieDict = [String : AnyObject]()
        
        self.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if let domain = domain {
                    if cookie.domain.contains(domain) {
                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                    }
                } else {
                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }
}

private extension WebkitManager {

    func deleteWKcookie(completion: @escaping() -> Void) {
    
        self.configuration.websiteDataStore = self.websiteDataStore

        let dispatchGroup = DispatchGroup()
        httpCookies.forEach {
            dispatchGroup.enter()
            self.websiteDataStore.httpCookieStore.delete($0) {
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            completion()
        })
    }
}
