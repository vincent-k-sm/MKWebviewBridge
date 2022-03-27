public struct MKWebview {
    
    public init() {
    }
    
    public static var debugEnabled = false {
        willSet {
            SystemUtils.shared.debugEnabled = newValue
            SystemUtils.shared.print("debugEnabled: \(newValue.description)" , self)
        }
    }
}
