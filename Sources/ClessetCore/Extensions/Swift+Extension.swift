//
//  Swift+Extension.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 21.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation

extension String {
    
    func upperCaseFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    func lowerCaseFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
    
}
