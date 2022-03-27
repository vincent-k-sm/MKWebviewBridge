//
//  LeakAvoider.swift
//


import Foundation
import WebKit

public class LeakAvoider: NSObject, WKScriptMessageHandler, WKScriptMessageHandlerWithReply {
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
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
    
    @available(iOS 14.0, *)
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        self.delegateReply?.userContentController(userContentController, didReceive: message, replyHandler: replyHandler)
    }
    
}
