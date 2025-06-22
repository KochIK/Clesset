//
//  Version.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 21.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import ArgumentParser

struct Version: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "Current Version"
    )
    
    func run() {
        print("0.0.1")
    }
    
}
