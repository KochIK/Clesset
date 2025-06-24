//
//  Logger.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 23.06.2025.
//

import Rainbow

public enum Logger: UInt8, Sendable {
    case error
    case warning
    case verbose
    
    public static let level: Self = .error
    
    public static func error(_ text: Any) {
        print("\(text)".red)
    }
    
    public static func warning(_ text: Any) {
        guard Self.level.rawValue >= Self.warning.rawValue else {
            return
        }
        
        print("\(text)".yellow)
    }
    
    public static func verbose(_ text: Any) {
        guard Self.level.rawValue >= Self.verbose.rawValue else {
            return
        }
        
        print(text)
    }
    
}
