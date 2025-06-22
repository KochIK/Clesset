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
    
    private(set) var state: State = .idle
    
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
            throw NSError()
        }
        
        state = .analyzing
        let resources = try await fileManager.resources(in: assetsPath, config: config)
        state = .analized(resources)
        
        return resources
    }
    
    public func unusedAssets(
        with config: SearchUnusedResourcesConfig,
        progress: @escaping AnalyzeProgessClosure
    ) async throws -> AnalyzeResult {
        guard case .analized(let resources) = state else {
            throw NSError()
        }
        
        guard !resources.isEmpty else {
            throw NSError()
        }
        
        return try await fileManager.unusedResources(
            at: path,
            resources: resources,
            config: config,
            progress: progress,
        )
    }
    
    public func remove(resources: Set<FileResource>) async throws {
        try await fileManager.remove(resources)
    }
    
}

extension Project {
    
    public enum State {
        case idle
        case analyzing
        case analized(Set<FileResource>)
    }
    
}
