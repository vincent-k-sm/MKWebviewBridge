//
//  File.swift
//
        

import Foundation
import UIKit
import WebKit

// MARK: - JavaScript Call back handler
@available(iOS 14.0, *)
extension MKWebViewController: WKScriptMessageHandlerWithReply {
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        var bodyMsg = ""
        if let body = message.body as? String {
            bodyMsg = body
        }
        for (key, value) in _replycallbacks {
            if message.name == key {
                value(bodyMsg, replyHandler)
                break
            }
        }
                
        MKWebKit.print("name: \(message.name), body: \(bodyMsg)")
    }
}

// MARK: - JavaScript Handler
extension MKWebViewController: WKScriptMessageHandler {
    open func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        var bodyMsg = ""
        if let body = message.body as? String {
            bodyMsg = body
        }
        MKWebKit.print("name: \(message.name), body: \(bodyMsg)")
        
        for (key, f) in _callbacks {
            if message.name == key {
                f(bodyMsg)
                break
            }
        }
    }
}
