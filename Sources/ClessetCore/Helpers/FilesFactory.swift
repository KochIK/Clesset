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
    
    static func createSourceFile(from pointer: UnsafeMutablePointer<dirent>, path: String) throws -> FileSource {
        var nameBuffer = [CChar](repeating: 0, count: Int(NAME_MAX) + 1)
        strncpy(&nameBuffer, &pointer.pointee.d_name.0, Int(NAME_MAX))
        
        guard let name = String(cString: nameBuffer, encoding: .utf8) else {
            throw NSError(domain: "no_name", code: 0)
        }
        
        // Skip current/prev/hidden paths
        guard name != ".", name != "..", !name.hasPrefix(".") else {
            throw NSError()
        }
        
        let path = "\(path)/\(name)"
        var statBuffer = stat()
        
        guard stat(path, &statBuffer) == 0 else {
            perror("stat-error")
            throw NSError(domain: "cannot_get_stats", code: 0)
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
            throw NSError(domain: "cannot_get_file_type", code: 0)
        }
        
        return FileSource(
            name: name,
            type: type,
            size: Int64(statBuffer.st_blocks * 512),
            path: path
        )
    }
    
}
