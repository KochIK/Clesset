//
//  ProjectFileScanner.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 24.06.2025.
//

import Foundation
import Darwin

final class ProjectFileScanner {
    
    func sourceFiles(
        in path: String,
        excludePaths: Set<String> = [],
        readBlock: (FileSource) async throws -> Void
    ) async throws(ImageResourceFinder.Error) {
        guard let dir = opendir(path) else {
            throw .cannotOpenDir(path)
        }
        
        guard !shouldPathIgnore(path: path, ignorePatterns: excludePaths) else {
            Logger.verbose("Ignore \(path)")
            closedir(dir)
            return
        }
        
        while let entry = readdir(dir) {
            do {
                let sourceFile = try SourceFileFactory.createSourceFile(
                    from: entry,
                    path: path
                )
                
                guard !shouldPathIgnore(path: sourceFile.path, ignorePatterns: excludePaths) else {
                    Logger.verbose("Ignore \(sourceFile.path)")
                    break
                }
                
                try await readBlock(sourceFile)
            } catch {
                Logger.verbose(error)
            }
        }
        
        closedir(dir)
    }
    
    func shouldPathIgnore(path: String, ignorePatterns: Set<String>) -> Bool {
        let triggeredPattern = ignorePatterns.first(where: {
            return fnmatch($0, path, .zero) == .zero
        })
        
        return triggeredPattern != nil
    }
    
}
