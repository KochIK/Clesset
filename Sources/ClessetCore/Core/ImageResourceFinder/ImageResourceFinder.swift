//
//  ImageResourceFinder.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 18.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation
import Darwin

final class ImageResourceFinder {
    
    private let fileScanner = ProjectFileScanner()
    
    func findAllResources(
        in path: String,
        config: SearchUnusedResourcesConfig
    ) async throws(ImageResourceFinder.Error) -> Set<FileResource> {
        var resources = Set<FileResource>()
        
        try await fileScanner.sourceFiles(in: path, excludePaths: config.excludedFiles) {
            switch $0.type {
            case .dir:
                do {
                    let innerDirResources = try await self.findAllResources(in: $0.path, config: config)
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
    
    func findUnusedResources(
        in path: String,
        resources: Set<FileResource>,
        config: SearchUnusedResourcesConfig,
        progress: @escaping AnalyzeProgessClosure,
    ) async throws(ImageResourceFinder.Error) -> AnalyzeResult {
        var actor = UnusedResourcesActor(
            resources: resources,
            searchStrategies: config.strategies
        )
        
        // ignore *.imageset and *.xcassets by default
        var excludedFiles = config.excludedFiles
        excludedFiles.insert("*.imageset")
        excludedFiles.insert("*.xcassets")
        Logger.verbose("*.imageset and *.xcassets has been added to excluded files")
        
        try await findUnusedResources(
            in: path,
            excludedFiles: config.excludedFiles,
            actor: &actor,
            progress: progress,
        )
        
        return await AnalyzeResult(usedResources: actor.usedResources, unusedResources: actor.unusedResources)
    }
    
    func remove(_ resources: Set<FileResource>) async throws(ImageResourceFinder.Error) {
        let fileManager = FileManager.default
        
        for resource in resources {
            do {
                try fileManager.removeItem(atPath: resource.path)
            } catch {
                throw .fileManagerError(error.localizedDescription)
            }
        }
    }
    
    private func parseResourceFolder(at sourceFile: FileSource) async throws(ImageResourceFinder.Error) -> FileResource? {
        var imageFiles = Set<FileSource>()
        
        try await fileScanner.sourceFiles(in: sourceFile.path) {
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
    
    private func findUnusedResources(
        in path: String,
        excludedFiles: Set<String>,
        actor: inout UnusedResourcesActor,
        progress: @escaping AnalyzeProgessClosure,
    ) async throws(ImageResourceFinder.Error) {
        try await fileScanner.sourceFiles(in: path, excludePaths: excludedFiles) { sourceFile in
            switch sourceFile.type {
            case .dir:
                try await findUnusedResources(
                    in: sourceFile.path,
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

extension ImageResourceFinder {
    
    public enum Error: ClessetError {
        case cannotOpenDir(String)
        case sourceFileNoName(String)
        case sourceFileSkipPath(String)
        case sourceFileCannotGetStats(String)
        case sourceFileUnknowType(String)
        case fileManagerError(String)
    }
    
}
