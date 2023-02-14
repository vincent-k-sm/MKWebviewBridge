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
        self.configuration.websiteDataStore = self.websiteDataStore

        let group = DispatchGroup()
        let que = DispatchQueue.main
        que.async(group: group) {
            self.httpCookies.forEach {
                group.enter()
                self.websiteDataStore.httpCookieStore.setCookie($0) {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: que, execute: {
            completion(self.configuration)
        })
        
        
    }
    
    public func setHeaders(headers: [String: String], completion: @escaping (Bool) -> Void) {
        
        if headers.isEmpty {
            completion(true)
        }
        
        let group = DispatchGroup()
        let que = DispatchQueue.main//(label: "headers", qos: .background)
        que.async(group: group) {
            headers.forEach { key, value in
                group.enter()
                self.headers[key] = value
                group.leave()
            }
        }
        
        group.notify(queue: que, execute: {
            completion(true)
        })
        
    }
    
    public func setCookies(cookies: [HTTPCookie] = [], completion: @escaping (WKWebViewConfiguration) -> Void) {
        
        let group = DispatchGroup()
        let que = DispatchQueue.main
        que.async(group: group) {
            cookies.forEach {
                group.enter()
                self.websiteDataStore.httpCookieStore.setCookie($0) {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: que, execute: {
            completion(self.configuration)
        })
    }
    
    /// Clears all cookie.
    /// - Parameter completion: completion block.
    public func removeCookies(completion: @escaping() -> Void) {
        self.deleteWKcookie {
            self.configuration.processPool = WKProcessPool()
            completion()
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

        let group = DispatchGroup()
        let que = DispatchQueue.main
        que.async(group: group) {
            self.httpCookies.forEach {
                group.enter()
                self.websiteDataStore.httpCookieStore.delete($0) {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: que, execute: {
            completion()
        })
    }
}

