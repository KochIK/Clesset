//
//  SearchUnusedResourcesConfig.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 21.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

public struct SearchUnusedResourcesConfig {
    
    public let excludedFiles: Set<String>
    public let strategies: Set<SearchStrategy>
    
    public init(excludedFiles: Set<String>, strategies: Set<SearchStrategy>) {
        self.excludedFiles = excludedFiles
        self.strategies = strategies
    }
    
}
