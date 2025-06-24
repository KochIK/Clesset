//
//  SourceFileManager.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 18.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation
import Darwin

final class SourceFileManager {
    
    private var processedFiles: UInt = .zero
    
    func resources(
        in path: String,
        config: SearchUnusedResourcesConfig
    ) async throws(SourceFileManager.Error) -> Set<FileResource> {
        var resources = Set<FileResource>()
        
        try await sourceFiles(in: path, excludePaths: config.excludedFiles) {
            switch $0.type {
            case .dir:
                do {
                    let innerDirResources = try await self.resources(in: $0.path, config: config)
                    resources.formUnion(innerDirResources)
                } catch {
                    Logger.warning(error)
                }
            case .file(let ext):
                switch ext {
                case .imageset:
                    guard let resource = try await self.parseResourceFolder(at: $0) else {
                        return
                    }
                    
                    guard !resource.imageFiles.isEmpty else {
                        Logger.warning("Empty imageset: \($0.name)")
                        return
                    }
                    
                    resources.insert(resource)
                case .jpg, .jpeg, .pdf, .png, .gif:
                    Logger.warning("Temporary skip: \($0.name)")
                    // resources.insert(FileResource($0, imageFiles: []))
                    return
                case .h, .m, .mm, .swift:
                    return
                }
            }
        }
        
        return resources
    }
    
    func unusedResources(
        at path: String,
        resources: Set<FileResource>,
        config: SearchUnusedResourcesConfig,
        progress: @escaping AnalyzeProgessClosure,
    ) async throws(SourceFileManager.Error) -> AnalyzeResult {
        var actor = SearchUnusedResourcesActor(
            resources: resources,
            searchStrategies: config.strategies
        )
        
        // ignore *.imageset and *.xcassets by default
        var excludedFiles = config.excludedFiles
        excludedFiles.insert("*.imageset")
        excludedFiles.insert("*.xcassets")
        Logger.verbose("*.imageset and *.xcassets has been added to excluded files")
        
        try await unusedResources(
            at: path,
            excludedFiles: config.excludedFiles,
            actor: &actor,
            progress: progress,
        )
        
        return await AnalyzeResult(usedResources: actor.usedResources, unusedResources: actor.unusedResources)
    }
    
    func remove(_ resources: Set<FileResource>) async throws(SourceFileManager.Error) {
        let fileManager = FileManager.default
        
        for resource in resources {
            do {
                try fileManager.removeItem(atPath: resource.path)
            } catch {
                throw .fileManagerError(error.localizedDescription)
            }
        }
    }
    
    private func sourceFiles(
        in path: String,
        excludePaths: Set<String> = [],
        readBlock: (FileSource) async throws -> Void
    ) async throws(SourceFileManager.Error) {
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
    
    private func shouldPathIgnore(path: String, ignorePatterns: Set<String>) -> Bool {
        let triggeredPattern = ignorePatterns.first(where: {
            return fnmatch($0, path, .zero) == .zero
        })
        
        return triggeredPattern != nil
    }
    
    private func parseResourceFolder(at sourceFile: FileSource) async throws(SourceFileManager.Error) -> FileResource? {
        var imageFiles = Set<FileSource>()
        
        try await sourceFiles(in: sourceFile.path) {
            switch $0.type {
            case .file(let ext):
                switch ext {
                case .jpeg, .jpg, .pdf, .png, .gif:
                    imageFiles.insert($0)
                case .imageset:
                    Logger.warning("Unexpected nested imageset")
                case .swift, .m, .mm, .h:
                    return
                }
            case .dir:
                break
            }
        }
        
        guard !imageFiles.isEmpty else {
            Logger.warning("imageset is empty")
            return nil
        }
        
        return FileResource(sourceFile, imageFiles: imageFiles)
    }
    
    private func unusedResources(
        at path: String,
        excludedFiles: Set<String>,
        actor: inout SearchUnusedResourcesActor,
        progress: @escaping AnalyzeProgessClosure,
    ) async throws(SourceFileManager.Error) {
        try await sourceFiles(in: path, excludePaths: excludedFiles) { sourceFile in
            switch sourceFile.type {
            case .dir:
                try await unusedResources(
                    at: sourceFile.path,
                    excludedFiles: excludedFiles,
                    actor: &actor,
                    progress: progress,
                )
                
            case .file(let ext):
                guard let availableStrategies = ext.availableStrategies else {
                    return
                }
                
                let searchPatterns = await actor.searchPatterns.compactMapValues { strategies in
                    return availableStrategies.compactMap { strategies[$0] }
                }
                
                guard !searchPatterns.isEmpty else {
                    return
                }
                
                await withTaskGroup { group in
                    guard let fd = SourceFileDescriptor(path: sourceFile.path) else {
                        Logger.error("Cannot open the file \(sourceFile.path)")
                        return
                    }
                    
                    searchPatterns.forEach { resource, patterns in
                        group.addTask {
                            let isMatched = patterns.contains(where: { pattern in
                                memmem(fd.pointer.ptr, fd.size, pattern, pattern.count) != nil
                            })
                            
                            return (resource, isMatched)
                        }
                    }
                    
                    for await searchResult in group {
                        if searchResult.1 {
                            Logger.verbose("\(sourceFile.name) resource has been found at \(sourceFile.name)")
                            await actor.found(resource: searchResult.0, at: sourceFile)
                        }
                    }
                    
                    let stat = await (UInt(actor.usedResources.count), actor.processed(file: sourceFile))
                    progress(stat.0, stat.1, sourceFile.name)
                    fd.close()
                }
            }
        }
    }
    
}

extension SourceFileManager {
    
    private actor SearchUnusedResourcesActor {
        
        private(set) var unusedResources: Set<FileResource>
        private(set) var usedResources: [FileResource: Set<FileSource>]
        private(set) var processedFilesCount: UInt
        private(set) var searchPatterns: [FileResource: [SearchStrategy: [UInt8]]]
        
        private let searchStrategies: Set<SearchStrategy>
        
        init(resources: Set<FileResource>, searchStrategies: Set<SearchStrategy>) {
            self.unusedResources = resources
            self.usedResources = [:]
            self.processedFilesCount = .zero
            self.searchStrategies = searchStrategies
            self.searchPatterns = unusedResources.reduce(into: [FileResource: [SearchStrategy: [UInt8]]]()) { result, asset in
                result[asset] = searchStrategies.reduce(into: [SearchStrategy: [UInt8]]()) {
                    $0[$1] = [UInt8]($1.searchPattern(resourceName: asset.name).data(using: .utf8)!)
                }
            }
        }
        
        func found(resource: FileResource, at sourceFile: FileSource) {
            unusedResources.remove(resource)
            searchPatterns.removeValue(forKey: resource)
            
            var foundAt = usedResources[resource] ?? []
            foundAt.insert(sourceFile)
            usedResources[resource] = foundAt
        }
        
        func processed(file: FileSource) -> UInt {
            processedFilesCount += 1
            
            return processedFilesCount
        }
    }
    
}

extension SourceFileManager {
    
    public enum Error: ClessetError {
        case cannotOpenDir(String)
        case sourceFileNoName(String)
        case sourceFileSkipPath(String)
        case sourceFileCannotGetStats(String)
        case sourceFileUnknowType(String)
        case fileManagerError(String)
    }
    
}
