//
//  SearchStrategy.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 18.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation

public enum SearchStrategy: String, CaseIterable, Sendable {
    case objc
    case swift
    case rSwift
    case rSwiftSimple
}

extension SearchStrategy {
    
    func pattern(resourceName: String) -> String {
        switch self {
        case .objc, .swift:
            return "\"\(resourceName)\""
        case .rSwift:
            let rSwiftName = Self.rSwiftSimple.pattern(resourceName: resourceName)
            return "R.image.\(rSwiftName)"
        case .rSwiftSimple:
            let rSwiftName = RSwiftNameGenerator(name: resourceName).value
            return ".\(rSwiftName)"
        }
    }
    
}
