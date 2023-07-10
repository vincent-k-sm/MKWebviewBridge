//
//  MKWebKit.swift
//
        
import MKUtils
import Foundation

public class MKWebKit {
    public static var enableDebug: Bool = false
    
    static func print(
        _ logs: Any...,
        separator: String = "\n",
        file: String = #file,
        line: Int = #line,
        function: String = #function,
        target: Any? = nil
    ) {
        if enableDebug {
            let targets = logs.map { target in
                return String("\(target)")
            }.joined(separator: " ")
            
            Debug.print(
                module: "MKWebKit",
                targets,
                separator: separator,
                file: file,
                line: line,
                function: function,
                target: target
            )
        }
    }
    
}
