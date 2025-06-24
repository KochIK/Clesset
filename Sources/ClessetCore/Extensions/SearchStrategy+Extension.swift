//
//  SearchStrategy+Extension.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 22.06.2025.
//

extension FileSource.Kind.Extension {
    
    var availableStrategies: Set<SearchStrategy>? {
        switch self {
        case .swift:
            return [.rSwift, .rSwiftSimple, .swift]
        case .m:
            return [.objc]
        case .mm, .h, .imageset, .jpg, .jpeg, .png, .pdf, .gif:
            return nil
        }
        
    }
    
}
