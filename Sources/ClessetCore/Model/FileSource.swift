//
//  FileSource.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 17.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation
import Darwin

public struct FileSource: Sendable, Hashable {
    
    public let name: String
    public let type: Kind
    public let size: Int64
    public let path: String
    
    public init(name: String, type: Kind, size: Int64, path: String) {
        self.name = name
        self.type = type
        self.size = size
        self.path = path
    }
    
}

extension FileSource {
    
    public enum Kind: Sendable, Hashable {
        case dir
        case file(Extension)
    }
    
}

extension FileSource.Kind {
    
    public enum Extension: String, Sendable {
        case swift
        case m
        case mm
        case h
        case imageset
        case jpg
        case jpeg
        case pdf
        case png
        case gif
    }
    
}
