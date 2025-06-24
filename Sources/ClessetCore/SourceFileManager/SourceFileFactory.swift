//
//  SourceFileFactory.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 17.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation
import Darwin

final class SourceFileFactory {
    
    static func createSourceFile(from pointer: UnsafeMutablePointer<dirent>, path: String) throws(SourceFileManager.Error) -> FileSource {
        var nameBuffer = [CChar](repeating: 0, count: Int(NAME_MAX) + 1)
        strncpy(&nameBuffer, &pointer.pointee.d_name.0, Int(NAME_MAX))
        
        guard let name = String(cString: nameBuffer, encoding: .utf8) else {
            throw .sourceFileNoName(path)
        }
        
        // Skip current/prev/hidden paths
        guard name != ".", name != "..", !name.hasPrefix(".") else {
            throw .sourceFileSkipPath(name)
        }
        
        let path = "\(path)/\(name)"
        var statBuffer = stat()
        
        guard stat(path, &statBuffer) == 0 else {
            throw .sourceFileCannotGetStats(name)
        }
        
        let type: FileSource.Kind
        if (statBuffer.st_mode & S_IFMT) == S_IFDIR {
            let isAssetDir = name.hasSuffix(FileSource.Kind.Extension.imageset.rawValue)
            type = isAssetDir ? .file(.imageset) : .dir
        }
        else if
            let rawFileExtension = name.components(separatedBy: ".").last,
            let fileExtension = FileSource.Kind.Extension(rawValue: rawFileExtension) {
            type = .file(fileExtension)
        }
        else {
            throw .sourceFileUnknowType(name)
        }
        
        return FileSource(
            name: name,
            type: type,
            size: Int64(statBuffer.st_blocks * 512),
            path: path
        )
    }
    
}
