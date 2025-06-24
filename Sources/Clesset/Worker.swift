//
//  Worker.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 22.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation
import ClessetCore

final class Worker {
    
    static func run(
        with mode: Clesset.Mode,
        projectPath: String,
        resourcesPath: String,
        excludedPaths: Set<String>,
        excludedStrategies: Set<String>
    ) async throws {
        let start = CFAbsoluteTimeGetCurrent()
        let project = Project(path: projectPath, assetsPath: resourcesPath)
        
        let _excludedStrategies = excludedStrategies.compactMap { SearchStrategy(rawValue: $0) }
        let searchStrategies = SearchStrategy.allCases.filter { !_excludedStrategies.contains($0) }
        let searchConfig = SearchUnusedResourcesConfig(
            excludedFiles: Set(excludedPaths),
            strategies: Set(searchStrategies)
        )
        
        print("""
            \("Run with config:".bold)
            Project path: \(projectPath)
            Resources path: \(resourcesPath)
            Excluded paths: \(excludedPaths)
            Excluded strategies: \(excludedStrategies)
            
            """)
        
        let projectResources = try await project.resources(config: searchConfig)
        
        print("Detected \(projectResources.count) resources.")
        
        let unusedResourcesResult = try await project.unusedAssets(with: searchConfig) { found, processed, processingFileName in
            print("\u{001B}[2K\rFound: \(found)/\(projectResources.count) | Processed: \(processed) <- \(processingFileName)", terminator: "")
            fflush(stdout)
        }
        
        let result = Result(
            totalResources: projectResources,
            unusedResources: unusedResourcesResult.unusedResources,
            usedResources: unusedResourcesResult.usedResources,
            time: CFAbsoluteTimeGetCurrent() - start
        )
        
        print("\n\("Summary".bold)\n\(result)")
        
        if mode == .clear {
            guard !result.unusedResources.isEmpty else {
                print("\nSkip. All resources are in use")
                return
            }
            
            try await project.remove(resources: result.unusedResources)
            print("\n\(result.unusedResources.count) resources have been removed.")
        }
    }
    
}

extension Worker {
    
    struct Result: CustomStringConvertible {
        
        let totalResources: Set<FileResource>
        let unusedResources: Set<FileResource>
        let usedResources: [FileResource: Set<FileSource>]
        let time: TimeInterval
        
        var description: String {
            let usedTable = Table(
                rows: usedResources.map {
                    Table.Row(resource: $0.key.name, size: String($0.key.size), files: $0.value.map { $0.name })
                }
            )
            
            let unusedTable = Table(
                rows: unusedResources.map {
                    Table.Row(resource: $0.name, size: String($0.size), files: ["None"])
                }
            )
            
            return """
                   Used:
                   \(usedTable.draw())
                   Unused:
                   \(unusedTable.draw())
                   
                   Total resources: \(totalResources.count) = \(totalResources.reduce(into: 0, { $0 += $1.size })) bytes
                   Used resources: \(usedResources.count) = \(usedResources.reduce(into: 0, { $0 += $1.key.size })) bytes
                   Unused resources: \(unusedResources.count) = \(unusedResources.reduce(into: 0, { $0 += $1.size })) bytes
                   Total time: \(time)
                   """
        }
        
    }
    
}
