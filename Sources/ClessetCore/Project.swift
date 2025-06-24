//
//  Project.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 18.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation

public final class Project: @unchecked Sendable {
    
    public private(set) var state: State = .idle
    
    public let path: String
    public let assetsPath: String
    
    private let fileManager: SourceFileManager
    
    public init(path: String, assetsPath: String) {
        self.path = path
        self.assetsPath = assetsPath
        self.fileManager = SourceFileManager()
    }
    
    public func resources(config: SearchUnusedResourcesConfig) async throws -> Set<FileResource> {
        guard case .idle = state else {
            throw Error.wrongState("should be `idle`, current: \(state)")
        }
        
        Logger.verbose("Start project processing")
        state = .processing
        let resources = try await fileManager.resources(in: assetsPath, config: config)
        state = .processed(resources)
        Logger.verbose("Processing has been finished. Resources count: \(resources.count)")
        
        return resources
    }
    
    public func unusedAssets(
        with config: SearchUnusedResourcesConfig,
        progress: @escaping AnalyzeProgessClosure
    ) async throws -> AnalyzeResult {
        guard case .processed(let resources) = state else {
            throw Error.wrongState("should be `processed`, current: `\(state)`")
        }
        
        guard !resources.isEmpty else {
            throw Error.noResources
        }
        
        Logger.verbose("Start searching for unused resources")
        return try await fileManager.unusedResources(
            at: path,
            resources: resources,
            config: config,
            progress: progress,
        )
    }
    
    public func remove(resources: Set<FileResource>) async throws {
        Logger.verbose("\(resources.count) resources will be removed")
        try await fileManager.remove(resources)
    }
    
}

extension Project {
    
    public enum State {
        case idle
        case processing
        case processed(Set<FileResource>)
    }
    
    public enum Error: ClessetError {
        case noResources
        case wrongState(String)
    }
    
}
