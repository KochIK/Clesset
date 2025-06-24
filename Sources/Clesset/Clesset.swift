//
//  main.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 02.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation
import ArgumentParser
import Rainbow
import ClessetCore

@main
struct Clesset: AsyncParsableCommand {
        
    @Argument(help: "Project path")
    var projectPath: String
    
    @Argument(help: "Resources path")
    var resourcesPath: String
    
    @Flag(
        help: """
        --summary: Show a summary of total and unused image assets without making any changes.
        --clear: Show a summary and remove all detected unused image assets. Use with caution.
        """
    )
    var mode: Mode = .summary
    
    @Option(
        name: [.customLong("excPaths"), .customLong("ep", withSingleDash: true)],
        parsing: .upToNextOption,
        help: """
        Ignore specific file or folder paths during the search.
        For example: `*.generated.swift`, `*/Generated/*`
        
        """
    )
    var excludedPaths: [String] = []
    
    @Option(
        name: [.customLong("excStrategies"), .customLong("es", withSingleDash: true)],
        parsing: .upToNextOption,
        help: """
        Exclude specific search strategies from analysis.
        
        Available values:
        `objc` – search .m files for `"<name>"`
        `swift` – search .swift files for `"<name>"`
        `rSwift` – search .swift files for `R.image.<name>`
        `rSwiftSimple` – search .swift for `.<name>` (extra R.swift coverage)
        
        """
    )
    var excludedStrategies: [String] = []
    
    func validate() throws {
        guard !projectPath.isEmpty else {
            throw ValidationError("`project-path` - empty")
        }
        
        guard !resourcesPath.isEmpty else {
            throw ValidationError("`resources-path` - empty")
        }
        
        try excludedStrategies.forEach {
            guard SearchStrategy(rawValue: $0) != nil else {
                throw ValidationError("\($0) - unknown strategy")
            }
        }
    }
    
    static let configuration = CommandConfiguration(
        abstract: "A cli tool for detecting unused image assets in iOS projects. Supports multiple search strategies including Swift, Objective-C, and R.swift.",
    )
    
    func run() async throws {
        try await Worker.run(
            with: mode,
            projectPath: projectPath,
            resourcesPath: resourcesPath,
            excludedPaths: Set(excludedPaths),
            excludedStrategies: Set(excludedStrategies),
        )
    }
    
}

extension Clesset {
    
    enum Mode: EnumerableFlag {
        case summary
        case clear
    }
    
}
