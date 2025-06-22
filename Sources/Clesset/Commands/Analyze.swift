//
//  Analyze.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 21.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation
import ArgumentParser
import Rainbow
import ClessetCore

struct Analyze: AsyncParsableCommand {
    
    static let cfonfiguration = CommandConfiguration(
        abstract: "Analyzes image assets in the project and lists unused `.imageset` files based on selected search strategies."
    )
    
    @Argument(help: "Project path")
    var projectPath: String
    
    @Argument(help: "Resources path")
    var resourcesPath: String
    
    @Option(
        name: .customShort("f"),
        parsing: .upToNextOption,
        help: """
        Ignore specific file or folder paths during the search.
        For example: `*.generated.swift`, `*/Generated/*`
        
        """
    )
    var excludedPaths: [String] = []
    
    @Option(
        name: .customShort("s"),
        parsing: .upToNextOption,
        help: """
        Exclude specific search strategies from analysis.
        Using `*DoubleCheck` strategies is recommended for broader coverage, especially with R.swift.
        
        Available values:
        `objc` – search .m files for `"<name>"`
        `swift` – search .swift files for `"<name>"`
        `rSwift` – search .swift files for `R.image.<name>`
        `simpleDoubleCheck` – search .m and .swift for `<name>`
        `rSwiftDoubleCheck` – search .swift for `<name>` (extra R.swift coverage)
        
        """
    )
    var excludedStratigies: [String] = []
    
    func validate() throws {
        guard !projectPath.isEmpty else {
            throw ValidationError("`project-path` - empty")
        }
        
        guard !resourcesPath.isEmpty else {
            throw ValidationError("`resources-path` - empty")
        }
        
        try excludedStratigies.forEach {
            guard SearchStrategy(rawValue: $0) != nil else {
                throw ValidationError("\($0) - unknown strategy")
            }
        }
    }
    
    func run() async throws {
        try await Worker.analyze(
            projectPath: projectPath,
            resourcesPath: resourcesPath,
            excludedPaths: Set(excludedPaths),
            excludedStrategirs: Set(excludedStratigies),
            shouldRemoveUnusedResources: false
        )
    }
    
}
