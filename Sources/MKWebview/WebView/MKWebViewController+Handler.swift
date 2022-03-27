//
//  MKWebViewController+Handler.swift
//


import Foundation
import UIKit
import WebKit

public typealias ReplyHandler = (result: Any?, error: String?)
public typealias ReplyCallBack = (handler: ReplyHandler, callBack: (Any?)->Void)

extension MKWebViewController {
    
    @available(iOS 14.0, *)
    /// iOS 14 이상 부터 javascript 통신 간 promise를 활용할 수 있습니다
    /// - Parameters:
    ///   - key: messageHandler 의 key
    ///   - handler: ReplyHandler Call back
    ///   - result: 결과처리
    ///   - UseCase
    /*
     --- javaScript ---
     var promise = window.webkit.messageHandlers.testWithPromise.postMessage( inputInfo );
     promise.then(
                  function(result) {
                      console.log(result); // "Stuff worked!"
                      successFunc( result )
                  },
                  function(err) {
                      console.log(err); // Error: "It broke"
                      errorFunc( err )
                  });
     
     --- override func onAddPostMessage() ---
     if #available(iOS 14.0, *) {
         addPostMessageReplyHandler("testWithPromise", handler: tResult, result: { result in
             print("Called")
         })
     }
     */
    public func addPostMessageReplyHandler(_ key: String, handler: ReplyHandler, result: @escaping ((Any?) -> Void)) {
        let v: ReplyCallBack = (handler, result)
        _replycallbacks[key] = v
        
        self.contentController.addScriptMessageHandler(
            LeakAvoider(delegate: self, delegateReply: self),
            contentWorld: .page,
            name: key
        )
    }

}

// MARK: - JavaScript Call back handler
@available(iOS 14.0, *)
extension MKWebViewController: WKScriptMessageHandlerWithReply {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        var bodyMsg = ""
        if let body = message.body as? String {
            bodyMsg = body
        }
        for (key, value) in _replycallbacks {
            if message.name == key {
                
                let v = value.handler
                replyHandler(v.result, v.error)
                value.callBack(bodyMsg)
                break
            }
        }
                
        SystemUtils.shared.print("name: \(message.name), body: \(bodyMsg)", self)
    }
}

// MARK: - JavaScript Handler
extension MKWebViewController: WKScriptMessageHandler {
    open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        var bodyMsg = ""
        if let body = message.body as? String {
            bodyMsg = body
        }
        SystemUtils.shared.print("name: \(message.name), body: \(bodyMsg)", self)
        
        for (key, f) in _callbacks {
            if message.name == key {
                f(bodyMsg)
                break
            }
        }
    }
}
