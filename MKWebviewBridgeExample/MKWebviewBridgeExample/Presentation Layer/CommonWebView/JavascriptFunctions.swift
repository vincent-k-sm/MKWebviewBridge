//
//  JavascriptFunctions.swift
//
        
import Foundation
import MKWebKit

// MARK: - Outbound
public enum JavaScripts: String, CaseIterable, ScriptInterface {
//    case newAccessToken = "NEW_ACCESS_TOKEN"
    case setToken = "setToken"
    case getStorage = "setStorage"
}

// MARK: - inbound
enum JavaScriptsHandlers: String, CaseIterable, ScriptInterface {
    case getToken   = "getToken"
    case setStorage = "setStorage"
    case getStorage = "getStorage"
    case showToast  = "showToast"
}
