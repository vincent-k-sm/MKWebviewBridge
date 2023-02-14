//
//  JavascriptFunctions.swift
//
        
import MKWebview
import Foundation

// MARK: - Outbound
enum JavaScripts: String, CaseIterable, ScriptInterface {
    case newAccessToken = "NEW_ACCESS_TOKEN"
    case setToken = "setToken"
    
}

// MARK: - inbound
enum JavaScriptsHandlers: String, CaseIterable, ScriptInterface {
    case getToken        = "getToken"
    case testWithPromise = "testWithPromise"
    case showToast       = "showToast"
}
