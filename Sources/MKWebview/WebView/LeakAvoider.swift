//
//  LeakAvoider.swift
//


import Foundation
import WebKit

class LeakAvoider: NSObject, WKScriptMessageHandler, WKScriptMessageHandlerWithReply {
    weak var delegate: WKScriptMessageHandler?
    weak var delegateReply: WKScriptMessageHandlerWithReply?
    
    init(delegate: WKScriptMessageHandler, delegateReply: WKScriptMessageHandlerWithReply) {
        self.delegate = delegate
        self.delegateReply = delegateReply
        super.init()
    }
    
    deinit {
        SystemUtils.shared.print("", self)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
    
    @available(iOS 14.0, *)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        self.delegateReply?.userContentController(userContentController, didReceive: message, replyHandler: replyHandler)
    }
    
}
