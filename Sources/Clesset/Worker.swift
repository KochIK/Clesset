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
    
    static func analyze(
        projectPath: String,
        resourcesPath: String,
        excludedPaths: Set<String>,
        excludedStrategirs: Set<String>,
        shouldRemoveUnusedResources: Bool,
    ) async throws {
        let start = CFAbsoluteTimeGetCurrent()
        let project = Project(path: projectPath, assetsPath: resourcesPath)
        
        let _excludedStrategies = excludedStrategirs.compactMap { SearchStrategy(rawValue: $0) }
        let searchStrategies = SearchStrategy.allCases.filter { !_excludedStrategies.contains($0) }
        let searchConfig = SearchUnusedResourcesConfig(
            excludedFiles: Set(excludedPaths),
            stratigies: Set(searchStrategies)
        )
        
        print("""
            \("Run analyze with config:".bold)
            Project path: \(projectPath)
            Reources path: \(resourcesPath)
            Excluded paths: \(excludedPaths)
            Excluded strategies: \(excludedStrategirs)
            
            """)
        
        let projectResources = try await project.resources(config: searchConfig)
        
        print("Detected \(projectResources.count) resources.")
        
        let unusedResourcesResult = try await project.unusedAssets(with: searchConfig) { found, processed, processingFileName in
            print("\u{001B}[2K\rFound: \(found)/\(projectResources.count) | Processed: \(processed) <- \(processingFileName)", terminator: "")
            fflush(stdout)
        }
        
        let result = Result(
            totalResourcrs: projectResources,
            unusedResources: unusedResourcesResult.unusedResources,
            usedResources: unusedResourcesResult.usedResources,
            time: CFAbsoluteTimeGetCurrent() - start
        )
        
        print("\n\(result)")
        
        if shouldRemoveUnusedResources {
            guard !result.unusedResources.isEmpty else {
                print("\nSkip. All resources are in use")
                return
            }
            
            try await project.remove(resources: result.unusedResources)
            print("\n\(result.unusedResources.count) resources has been removed.")
        }
    }
    
}

extension Worker {
    
    struct Result: CustomStringConvertible {
        
        let totalResourcrs: Set<FileResource>
        let unusedResources: Set<FileResource>
        let usedResources: [FileResource: Set<FileSource>]
        let time: TimeInterval
        
        var description: String {
            let used = usedResources.reduce(into: "") {
                let lastIndex = $1.value.count - 1
                let foundAt = $1.value.enumerated().reduce(into: "") {
                    let symbol = lastIndex == $1.offset ? "└──" : "├──"
                    $0 += " \(symbol) \($1.element.name)\n"
                }
                
                $0 += "\n\($1.key.name)\n\(foundAt)"
            }
            
            return """
                   \("Summary".bold)
                   \(used)
                   Total resources: \(totalResourcrs.count) / \(totalResourcrs.reduce(into: 0, { $0 += $1.size })) bytes
                   Used resources: \(usedResources.count) / \(usedResources.reduce(into: 0, { $0 += $1.key.size })) bytes
                   Unused resources: \(unusedResources.count) / \(unusedResources.reduce(into: 0, { $0 += $1.size })) bytes
                   Total time: \(time)
                   """
        }
        
    }
    
}
