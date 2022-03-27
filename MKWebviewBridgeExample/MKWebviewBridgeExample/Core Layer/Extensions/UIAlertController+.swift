//
//  UIAlertController+.swift
//


import Foundation
import UIKit

extension UIAlertController {
    public typealias AlertActionHandler = ((UIAlertAction) -> Void)

    /**
    디버그용 Simple message Popup
    UIAlertController.commonDebugAlert(errorMsg: "asd", confirmHandler: { [weak self] action in
        guard let self = self else { return }
        self.kit.print("Confirm 누름!")
        
    })
    */
    static public func commonDebugAlert(title: String = "DEBUG Error", errorMsg: String, confirmHandler: AlertActionHandler? = nil) {

        let title = title
        let msg = errorMsg

        var action: UIAlertAction!
        if let confirmAction = confirmHandler {
            action = UIAlertAction(title: "confirm", style: .destructive, handler: confirmAction)
        }
        else {
            action = UIAlertAction(title: "confirm", style: .destructive) { _ in

            }
        }

        showAlert(title: title, message: msg, actions: [action])

    }

    /** Simple message Popup*/
    static public func showMessage(_ message: String, confirmTitle: String = "확인") {
        showAlert(title: "", message: message, actions: [UIAlertAction(title: confirmTitle, style: .cancel, handler: nil)])
    }

    /**
    let alertAction = UIAlertAction(title: "ok", style: .cancel)
    UIAlertController.showAlert(title: "Notice", message: "Save Draft Btn Tapped", actions: [alertAction])
    */
    static public func showAlert(title: String?, message: String?, actions: [UIAlertAction], style: UIAlertController.Style = .alert) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: style)
            for action in actions {
                alert.addAction(action)
            }

            if let topVC = UIApplication.topViewController() {
                topVC.present(alert, animated: true, completion: nil)
            }

        }
    }
    
    static public func showAlertFullSize(title: String?, message: String?, actions: [UIAlertAction], style: UIAlertController.Style = .alert) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: style)
            // Fullsize 인 경우 align추가
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            let messageText = NSAttributedString(
                string: message ?? "",
                attributes: [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                    NSAttributedString.Key.foregroundColor: UIColor.gray
                    
                ]
            )
            alert.setValue(messageText, forKey: "attributedMessage")
            
            for action in actions {
                alert.addAction(action)
            }

            let newWidth = UIScreen.main.bounds.width * 0.90
            
            let widthConstraint = NSLayoutConstraint(item: alert.view as Any,
                                                         attribute: .width,
                                                         relatedBy: .equal,
                                                         toItem: nil,
                                                         attribute: .notAnAttribute,
                                                         multiplier: 1,
                                                         constant: newWidth)
            alert.view.addConstraint(widthConstraint)
            let firstContainer = alert.view.subviews[0]
            
            let constraint = firstContainer.constraints.filter({ return $0.firstAttribute == .width && $0.secondItem == nil })
            firstContainer.removeConstraints(constraint)
            
            alert.view.addConstraint(NSLayoutConstraint(item: firstContainer,
                                                        attribute: .width,
                                                        relatedBy: .equal,
                                                        toItem: alert.view,
                                                        attribute: .width,
                                                        multiplier: 1.0,
                                                        constant: 0))
            
            let innerBackground = firstContainer.subviews[0]
            let innerConstraints = innerBackground.constraints.filter({ return $0.firstAttribute == .width && $0.secondItem == nil })
            innerBackground.removeConstraints(innerConstraints)
            firstContainer.addConstraint(NSLayoutConstraint(item: innerBackground,
                                                            attribute: .width,
                                                            relatedBy: .equal,
                                                            toItem: firstContainer,
                                                            attribute: .width,
                                                            multiplier: 1.0,
                                                            constant: 0))
            
            if let topVC = UIApplication.topViewController() {
                topVC.present(alert, animated: true, completion: nil)
            }

        }
    }

}
