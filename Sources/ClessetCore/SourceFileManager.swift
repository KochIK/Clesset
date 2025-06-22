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

final class SourceFileManager: @unchecked Sendable {
    
    private var foundUsedResources: UInt = .zero
    private var processedFiles: UInt = .zero
    
    func resources(in path: String, config: SearchUnusedResourcesConfig) async throws -> Set<FileResource> {
        var resources = Set<FileResource>()
        
        try await sourceFiles(in: path, excludePaths: config.excludedFiles) {
            switch $0.type {
            case .dir:
                do {
                    let innerDirResources = try await self.resources(in: $0.path, config: config)
                    resources.formUnion(innerDirResources)
                } catch {
                    // print(error)
                }
            case .file(let ext):
                switch ext {
                case .imageset:
                    guard let resource = try await self.parseResourceFolder(at: $0), !resource.imageFiles.isEmpty else {
                        return
                    }
                    resources.insert(resource)
                case .jpg, .jpeg, .pdf, .png, .gif:
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
    ) async throws -> AnalyzeResult {
        var actor = SearchUnusedResourcesActor(
            resources: resources,
            searchStrategies: config.stratigies
        )
        
        foundUsedResources = .zero
        processedFiles = .zero
        
        // ignore *.imageset and *.xcassets by default
        var excludedFiles = config.excludedFiles
        excludedFiles.insert("*.imageset")
        excludedFiles.insert("*.xcassets")
        
        try await unusedResources(
            at: path,
            excludedFiles: config.excludedFiles,
            actor: &actor,
            progress: progress,
        )
        
        return await AnalyzeResult(usedResources: actor.usedResources, unusedResources: actor.unusedResources)
    }
    
    func remove(_ resources: Set<FileResource>) async throws {
        let fileManager = FileManager.default
        
        for resource in resources {
            try fileManager.removeItem(atPath: resource.path)
        }
    }
    
    private func sourceFiles(
        in path: String,
        excludePaths: Set<String> = [],
        readBlock: (FileSource) async throws -> Void
    ) async throws {
        guard let dir = opendir(path) else {
            throw NSError()
        }
        
        guard !shoudPathIgnore(path: path, ignorePatterns: excludePaths) else {
            return
        }
        
        while let entry = readdir(dir) {
            do {
                let sourceFile = try SourceFileFactory.createSourceFile(
                    from: entry,
                    path: path
                )
                
                guard !shoudPathIgnore(path: sourceFile.path, ignorePatterns: excludePaths) else {
                    return
                }
                
                try await readBlock(sourceFile)
            } catch {
                // print("sourceFilesError=\(error)")
            }
        }
        
        closedir(dir)
    }
    
    private func shoudPathIgnore(path: String, ignorePatterns: Set<String>) -> Bool {
        let triggeredPattern = ignorePatterns.first(where: {
            return fnmatch($0, path, .zero) == .zero
        })
        
        return triggeredPattern != nil
    }
    
    private func parseResourceFolder(at sourceFile: FileSource) async throws -> FileResource? {
        var imageFiles = Set<FileSource>()
        
        try await sourceFiles(in: sourceFile.path) {
            switch $0.type {
            case .file(let ext):
                switch ext {
                case .jpeg, .jpg, .pdf, .png, .gif:
                    imageFiles.insert($0)
                    return
                case .imageset:
                    // print("error/warn")
                    return
                case .swift, .m, .mm, .h:
                    return
                }
            case .dir:
                break
            }
        }
        
        guard !imageFiles.isEmpty else {
            // print("[ERROR] imageset is empty")
            return nil
        }
        
        return FileResource(sourceFile, imageFiles: imageFiles)
    }
    
    private func unusedResources(
        at path: String,
        excludedFiles: Set<String>,
        actor: inout SearchUnusedResourcesActor,
        progress: @escaping AnalyzeProgessClosure,
    ) async throws {
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
                let availableSearchStrategies: Set<SearchStrategy>
                
                switch ext {
                case .m:
                    availableSearchStrategies = [.objc, /*.simpleDoubleCheck*/]
                    
                case .swift:
                    availableSearchStrategies = [.rSwift, .swift, .rSwiftDoubleCheck, /*.simpleDoubleCheck*/]
                    
                case .imageset, .h, .mm, .jpg, .jpeg, .pdf, .png, .gif:
                    return
                }
                
                let searchPatterns = await actor.resourcesSearchPatterns.compactMapValues { value -> [[UInt8]]? in
                    return value.filter { availableSearchStrategies.contains($0.key) }.values.map { $0 }
                }
                
                processedFiles += 1
                progress(self.foundUsedResources, self.processedFiles, sourceFile.name)
                await withTaskGroup { group in
                    guard let fd = FileDescriptor(path: sourceFile.path) else {
                        // print("[ERROR] cannot open file")
                        return
                    }
                    
                    searchPatterns.forEach { resource in
                        resource.value.forEach { resourceSearchPattern in
                            group.addTask {
                                let isMatched = memmem(fd.pointer.ptr, fd.size, resourceSearchPattern, resourceSearchPattern.count) != nil
                                return (resource.key, isMatched)
                            }
                        }
                    }
                    
                    for await searchResult in group {
                        if searchResult.1 {
                            if await actor.founded(resource: searchResult.0, at: sourceFile) {
                                foundUsedResources += 1
                            }
                        }
                    }
                    
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
        private(set) var resourcesSearchPatterns: [FileResource: [SearchStrategy: [UInt8]]]
        
        let searchStrategies: Set<SearchStrategy>
        
        init(resources: Set<FileResource>, searchStrategies: Set<SearchStrategy>) {
            self.unusedResources = resources
            self.usedResources = [:]
            self.searchStrategies = searchStrategies
            self.resourcesSearchPatterns = unusedResources.reduce(into: [FileResource: [SearchStrategy: [UInt8]]]()) { result, asset in
                result[asset] = searchStrategies.reduce(into: [SearchStrategy: [UInt8]]()) {
                    $0[$1] = [UInt8]($1.searchPattern(resourceName: asset.name).data(using: .utf8)!)
                }
            }
        }
        
        func founded(resource: FileResource, at sourcFile: FileSource)  -> Bool {
            let isRemoved = unusedResources.remove(resource) != nil
            resourcesSearchPatterns.removeValue(forKey: resource)
            
            var foundAt = usedResources[resource] ?? []
            foundAt.insert(sourcFile)
            usedResources[resource] = foundAt
            
            return isRemoved
        }
        
    }
    
}
