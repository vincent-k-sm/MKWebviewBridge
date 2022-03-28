//
//  ProgressView.swift
//


import Foundation
import NVActivityIndicatorView
import SnapKit
import MKFoundation
import UIKit

class ProgressView {
    static let shared = ProgressView()
    
    fileprivate let view: UIView = UIView()
    var showAble = true
    var isShow: Bool = false
    var nvActivityIndicatorView: NVActivityIndicatorView?
    
    private init() { }
    
    deinit {
        print("\(Self.self) -- deinit")
    }
    
    func show(isBackground: Bool = false) {
        if let window = UIApplication.shared.windows.last,
           !isShow && showAble {
            isShow = true
            
            window.addSubview(view)
            view.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalToSuperview()
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            if nvActivityIndicatorView == nil {
                nvActivityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0,
                                                                                y: 0,
                                                                                width: 40,
                                                                                height: 40),
                                                                  type: .circleStrokeSpin,
                                                                  color: UIColor.setColorSet(.purple500),
                                                                  padding: 0)
                view.addSubview(nvActivityIndicatorView!)
                nvActivityIndicatorView?.snp.makeConstraints { make in
                    make.width.equalTo(40)
                    make.height.equalTo(40)
                    make.centerX.equalToSuperview()
                    make.centerY.equalToSuperview()
                }
            }
            if isBackground {
                view.backgroundColor = .black.withAlphaComponent(0.5)
            }
            else {
                view.backgroundColor = .clear
            }
            nvActivityIndicatorView?.startAnimating()
        }
    }
    
    func dismiss() {
        isShow = false
        nvActivityIndicatorView?.stopAnimating()
        view.removeFromSuperview()
    }
    
    func createIndicatorView() -> NVActivityIndicatorView {
        return NVActivityIndicatorView(frame: CGRect(x: 0,
                                                     y: 0,
                                                     width: 40,
                                                     height: 40),
                                       type: .circleStrokeSpin,
                                       color: UIColor.setColorSet(.purple500),
                                       padding: 0)
    }
}
