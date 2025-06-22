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

@main
struct Clesset: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "A cli tool for detecting unused image assets in iOS projects. Supports multiple search strategies including Swift, Objective-C, and R.swift.",
        subcommands: [Analyze.self, Clear.self, Version.self],
        defaultSubcommand: Version.self
    )
    
}
