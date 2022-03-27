//
//  MKWebViewConfiguration.swift
//


import Foundation

/// Webview를 세팅하는 MKWebViewConfiguration 입니다
/// - Parameters:
///   - host: deeplink 에 활용되는 host가 적용됩니다 (plist 내 등록된 url Types를 모두 체크합니다)
///   - urlString: landing url 을 설정합니다
///   - title: 네비게이션 바 내 페이지 타이틀을 설정합니다
///   - leftBtn: 좌측 버튼 (<-) 을 활성화 합니다
///   - rightBtn: 우측 버튼 (x) 을 활성화 합니다
///   - navigationColor: 네비게이션 바의 색상을 지정합니다 (hexString)
///   - statusBarColor: 상단 스테이터스 바의 색상을 지정합니다 (hexString)
///   - tintColor: 네비게이션 바 내 버튼, 타이틀 등의 색상을 지정합니다 (hexString)
///   - removeStack:기존 stack 에 쌓여있는 모든  controller를 제거합니다
///   - navigationBarIsEnable: host, urlString, navigationBarIsEnable, removeStack 값에 따라 네비게이션바 노출 여부를 설정합니다
///   - important:host, urlString, navigationBarIsEnable, removeStack 을 제외하고 모든 value가 nil 인 경우 네비게이션바가 노출되지 않습니다
public struct MKWebViewConfiguration: Codable {
    public var host: String                = ""
    public var urlString: String           = ""
    public var title: String?              = nil
    public var leftBtn: Bool?              = nil
    public var rightBtn: Bool?             = nil
    public var navigationColor: String?    = nil
    public var statusBarColor: String?     = nil
    public var tintColor: String?          = nil
    public var removeStack: Bool?          = nil
    public var navigationBarIsEnable: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case urlString = "url"
        case title
        case leftBtn
        case rightBtn
        case navigationColor
        case tintColor
        case statusBarColor
        case removeStack
    }
    
    public init(
        host: String                = "",
        urlString: String           = "",
        title: String?              = nil,
        leftBtn: Bool?              = nil,
        rightBtn: Bool?             = nil,
        navigationColor: String?    = nil,
        statusBarColor: String?     = nil,
        tintColor: String?          = nil,
        removeStack: Bool?          = nil
    ) {
        self.host = host
        self.urlString = urlString
        self.title = title
        self.leftBtn = leftBtn
        self.rightBtn = rightBtn
        self.navigationColor = navigationColor
        self.statusBarColor = statusBarColor
        self.tintColor = tintColor
        self.removeStack = removeStack
        self.navigationBarIsEnable = self.isShowNavigation()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decodeIfPresent(String.self, forKey: .urlString) ?? ""
        self.urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? nil
        if let leftBtnIsEnable = try container.decodeIfPresent(String.self, forKey: .leftBtn) {
            self.leftBtn = (leftBtnIsEnable as NSString).boolValue
        }
        else {
            self.leftBtn = nil
        }
        
        if let rightBtnIsEnable = try container.decodeIfPresent(String.self, forKey: .rightBtn) {
            self.rightBtn = (rightBtnIsEnable as NSString).boolValue
        }
        else {
            self.rightBtn = nil
        }
        
        self.tintColor = try container.decodeIfPresent(String.self, forKey: .tintColor) ?? nil
        
        self.navigationColor = try container.decodeIfPresent(String.self, forKey: .navigationColor) ?? nil
        
        self.statusBarColor = try container.decodeIfPresent(String.self, forKey: .statusBarColor) ?? nil
        
        if let removeStack = try container.decodeIfPresent(String.self, forKey: .removeStack) {
            self.removeStack = (removeStack as NSString).boolValue
        }
        else {
            self.removeStack = nil
        }
        
        self.navigationBarIsEnable = self.isShowNavigation()
    }
    
    func isShowNavigation() -> Bool {
        let checkValues = Mirror(reflecting: self).children
            .filter({ $0.label != "host" && $0.label != "urlString" && $0.label != "navigationBarIsEnable" && $0.label != "removeStack" })
        let hasMissingValues = checkValues
            .filter({
            if case Optional<Any>.some(_) = $0.value {
                return false
            } else {
                return true
            }
        })
        return hasMissingValues.count != checkValues.count
        
    }
    
}
