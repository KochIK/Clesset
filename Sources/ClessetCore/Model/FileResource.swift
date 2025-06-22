//
//  FileResource.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 21.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

public struct FileResource: Sendable, Hashable {
    
    public let name: String
    public let path: String
    public let size: Int64
    public let imageFiles: Set<FileSource>
    
    public init(_ resourceFolder: FileSource, imageFiles: Set<FileSource>) {
        self.name = resourceFolder.name.replacingOccurrences(of: ".imageset", with: "")
        self.path = resourceFolder.path
        self.imageFiles = imageFiles
        self.size = imageFiles.reduce(into: 0) { $0 += $1.size }
    }
    
}
