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
    // case simpleDoubleCheck
    case rSwiftDoubleCheck
    
}

extension SearchStrategy {
    
    func searchPattern(resourceName: String) -> String {
        switch self {
        case .objc, .swift:
            return "\"\(resourceName)\""
        case .rSwift:
            let rSwiftName = RSwiftNameGenerator(name: resourceName).value
            return "R.image.\(rSwiftName)"
            // case .simpleDoubleCheck:
            // return "\(assetName)"
        case .rSwiftDoubleCheck:
            let rSwiftName = RSwiftNameGenerator(name: resourceName).value
            return "\(rSwiftName)"
        }
    }
    
}
