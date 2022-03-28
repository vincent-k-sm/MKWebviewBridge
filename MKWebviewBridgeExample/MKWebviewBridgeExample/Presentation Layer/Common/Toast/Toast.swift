//
//  Toast.swift
//


import Foundation
import UIKit
import MKFoundation

public class MKToast: UIView {
    
    deinit {
        print("\(Self.self) -- deinit")
    }
    // MARK: - 내부에서 사용되는 변수 및 상수
    
    /**
     Toast에 나타나는 글자의 String 값입니다.
     */
    private var text: String? {
        get { return label.text }
        set { label.text = newValue }
    }
    
    /**
     Toast의 지속시간입니다.
     */
    private var duration: ToastDuration
    
    /**
     Toast의 지속시간에 관한 enum입니다.
     */
    public enum ToastDuration {
        case short
        case long
        
        fileprivate var value: Double {
            switch self {
            case .short:
                return 1.5

            case .long:
                return 3
            }
        }
    }
    
    /**
     내부에서 사용되는 각종 레이아웃 관련 수치입니다.
     */
    private enum Dimension {
        enum Margin {
            static let horizontal: CGFloat = 20
            static let vertical: CGFloat = 60
        }
        
        enum Padding {
            static let horizontal: CGFloat = 8
            static let vertical: CGFloat = 14
        }
    }
    
    // MARK: - 뷰
    
    /**
     Toast에 나타나는 글자의 Label입니다.
     */
    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.setColorSet(.grey50)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    /**
     생성자는 private으로 막혀있습니다.
     생성자 대신 static으로 정의된 makeToast() 함수를 사용해주세요.
     */
    private init(text: String?, duration: ToastDuration) {
        self.duration = duration
        super.init(frame: .zero)
        self.text = text
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     뷰를 세팅합니다.
     */
    private func setupView() {
        setLayouts()
        setProperties()
    }
    
    /**
     레이아웃을 세팅합니다.
     */
    private func setLayouts() {
        setViewHierarchy()
        setAutolayout()
    }
    
    /**
     뷰의 위계를 세팅합니다.
     */
    private func setViewHierarchy() {
        self.addSubview(label)
    }
    
    /**
     뷰의 오토레이아웃을 세팅합니다.
     label의 width에 lessThanOrEqualToSuperview() 를 사용했기 때문에
     label이 1줄일 때는 중앙정렬, 2줄 이상일 때는 좌측정렬이 됩니다.
     */
    private func setAutolayout() {
        label.snp.makeConstraints {
            $0.width.lessThanOrEqualToSuperview().inset(Dimension.Padding.horizontal)
            $0.height.equalToSuperview().inset(Dimension.Padding.vertical)
            $0.center.equalToSuperview()
        }
    }
    
    /**
     뷰의 프로퍼티를 세팅합니다.
     */
    private func setProperties() {
        self.backgroundColor = UIColor.setColorSet(.grey800)// .withAlphaComponent(0.5)
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.alpha = 0.0
    }
    
    // MARK: - Toast Lifecycle
    
    /**
     Toast를 생성하는 함수입니다.
     함수가 실행되면 화면 내 적절한 위치에 Toast가 생성됩니다.
     
     - Parameters:
         - text: Toast에 나타날 글귀입니다.
         - duration: Toast가 지속되는 시간입니다. .short는 1.5초, .long은 3초입니다.
     
     ```
     MKToast.makeToast(text: "Toast 내용",
                        duration: .long)
     ```
     */
    public static func makeToast(text: String?, duration: ToastDuration = .short) {
        guard let text = text else {
            return
        }
        if text.isEmpty {
            return
        }
        let toast = MKToast(
            text: text,
            duration: duration
        )
        
//        guard let delegate = UIApplication.shared.delegate,
//              let optionalWindow = delegate.window,
//              let window = optionalWindow
//        else { return }
        guard let window = UIWindow.key else { return }
        DispatchQueue.main.async {
            window.addSubview(toast)
            guard let view = window.subviews.first else { return }
            toast.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Dimension.Margin.vertical)
                make.leading.trailing.equalTo(window.safeAreaLayoutGuide).inset(Dimension.Margin.horizontal)
            }
            
            toast.showToast()
        }
        
    }
    
    /**
     Toast의 alpha 값을 0.0에서 1.0으로 변경하여 Toast가 보이도록 만듭니다.
     */
    private func showToast() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0.0,
            options: .curveEaseIn,
            animations: {
                self.alpha = 1.0
            }, completion: { _ in
                self.hideToastAfterDuration()
            })
    }
    
    /**
     Duration으로 설정한 시간동안 Toast를 유지한 후
     alpha 값을 1.0에서 0.0으로 변경하여 Toast가 사라지도록 만듭니다.
     */
    private func hideToastAfterDuration() {
        UIView.animate(
            withDuration: 0.5,
            delay: self.duration.value,
            options: .curveEaseOut,
            animations: {
                self.alpha = 0.0
            }, completion: { _ in
                self.removeToast()
            })
    }
    
    /**
     토스트를 제거합니다.
     */
    private func removeToast() {
        self.removeFromSuperview()
    }
    
}
