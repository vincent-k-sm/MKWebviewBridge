//
//  MKWebViewConfiguration.swift
//


import Foundation

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
