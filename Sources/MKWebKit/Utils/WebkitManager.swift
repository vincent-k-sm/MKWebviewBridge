//
//  WebkitManager.swift
//
        

import Foundation
import WebKit

public final class WebkitManager {
    public static let shared = WebkitManager()
    public var javascriptEnabled: Bool = true
    
    public var configuration: WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.preferences = defaultPreferences
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = javascriptEnabled
        }
        configuration.processPool = defaultProcessPool
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        //        configuration.userContentController = defaultUserContentController
        return configuration
    }
    
    var defaultPreferences: WKPreferences {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = javascriptEnabled
        preferences.javaScriptCanOpenWindowsAutomatically = false
        return preferences
    }
    
    var defaultProcessPool: WKProcessPool = WKProcessPool()
    
    //    var defaultUserContentController: WKUserContentController {
    //        return WKUserContentController()
    //    }
    
    public var headers: [String: String] = [:]
    
    /// Cookies from http cookie store.
    //    public var httpCookies: [HTTPCookie] {
    //        return HTTPCookieStorage.shared.cookies ?? [HTTPCookie]()
    //    }
    
    public func setHeaders(headers: [String: String], completion: @escaping (Bool) -> Void) {
        
        if headers.isEmpty {
            completion(true)
        }
        
        DispatchQueue.main.async {  [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            headers.forEach { key, value in
                self.headers[key] = value
            }
            completion(true)
        }
    }
    
}

// MARK: - Manage Cookie
public extension WebkitManager {
    
    func setCookies(cookies: [HTTPCookie] = [], completion: @escaping () -> Void) {
        if cookies.isEmpty {
            completion()
            return
        }
        let dataStore = self.configuration.websiteDataStore
        let group = DispatchGroup()
        let que = DispatchQueue.main
        que.async(group: group) {
            cookies.forEach {
                group.enter()
                dataStore.httpCookieStore.setCookie($0) {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: que, execute: {
            completion()
        })
    }
    
    func removeCookies(names: [String], completion: @escaping () -> Void) {
        let dataStore = self.configuration.websiteDataStore
        
        if names.isEmpty {
            completion()
            return
        }
        
        let group = DispatchGroup()
        let que = DispatchQueue.main
        dataStore.httpCookieStore.getAllCookies({ cookies in
            que.async(group: group) {
                
                if cookies.isEmpty {
                    completion()
                    return
                }
                
                cookies.forEach { cookie in
                    group.enter()
                    if names.contains(cookie.name) {
                        dataStore.httpCookieStore.delete(cookie, completionHandler: {
                            group.leave()
                        })
                    }
                    else {
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: que, execute: {
                completion()
            })
        })
    }
    
    /// Clear cookies.
    /// - Parameter completion: completion block.
    func clearCookies(completion: @escaping () -> Void) {
        let dataStore = self.configuration.websiteDataStore
        let group = DispatchGroup()
        let que = DispatchQueue.main
        dataStore.httpCookieStore.getAllCookies({ cookies in
            que.async(group: group) {
                if cookies.isEmpty {
                    completion()
                    return
                }
                
                cookies.forEach { cookie in
                    group.enter()
                    dataStore.httpCookieStore.delete(cookie, completionHandler: {
                        group.leave()
                    })
                }
            }
            
            group.notify(queue: que, execute: {
                completion()
            })
        })
    }
   
    func getCookies(for domain: String? = nil, completion: @escaping ([String : Any])->())  {
        var cookieDict = [String : AnyObject]()
        let dataStore = self.configuration.websiteDataStore
        dataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if let domain = domain {
                    if cookie.domain.contains(domain) {
                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                    }
                }
                else {
                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }
}

/// MARK: Clearable
public extension WebkitManager {
    func clearDatas(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: websiteDataTypes, completionHandler: { types in
            var storedDataCount: Int = types.count
            if storedDataCount == 0 {
                completion()
            }
            else {
                types.forEach({ type in
                    dataStore.removeData(ofTypes: websiteDataTypes, for: [type], completionHandler: {
                        storedDataCount -= 1
                        if storedDataCount == 0 {
                            completion()
                        }
                    })
                })
            }
        })
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    func clearAllData(completion: @escaping () -> Void) {
        self.clearCookies(completion: { [weak self] in
            guard let self = self else { return }
            
            self.clearDatas(completion: { [weak self] in
                guard let self = self else { return }
                
                self.clearCache()
                completion()
            })
        })
        
        
    }
}
