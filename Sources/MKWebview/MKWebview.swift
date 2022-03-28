public struct MKWebview {
    
    public static let shared = MKWebview()
    
    public init() {
        
    }
    
    public static var debugEnabled = false {
        willSet {
            SystemUtils.shared.debugEnabled = newValue
            SystemUtils.shared.print("debugEnabled: \(newValue.description)" , self)
        }
    }
    
    public func clearCookies(completion: (() -> Void)? = nil) {
        WebkitManager.shared.removeCookies {
            completion?()
        }
    }
}
