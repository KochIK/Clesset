//
//  ImageResourceFinderActor.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 24.06.2025.
//

extension ImageResourceFinder {
    
    actor UnusedResourcesActor {
        
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
                    $0[$1] = [UInt8]($1.pattern(resourceName: asset.name).data(using: .utf8)!)
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
