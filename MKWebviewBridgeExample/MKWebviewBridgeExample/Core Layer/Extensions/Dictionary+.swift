//
//  Dictionary+.swift
//


import Foundation

extension Dictionary where Key == String, Value: Any {
    public func toJsonString() -> String? {
        
        if let data = try? JSONSerialization.data(withJSONObject: self, options:[]) {
            let value = String(data: data, encoding: .utf8)
            var result = value!.replacingOccurrences(of: "\"", with: "\\\"")
            result = result.replacingOccurrences(of: "\'", with: "\\\'")
            return result
            
        }
        else {
            print("dictionary to json nii")
            return nil
        }
    }
}
