//
//  Types.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 22.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation

public typealias AnalyzeProgessClosure = (_ found: UInt, _ processed: UInt, _ processingFileName: String) -> Void
public typealias AnalyzeResult = (usedResources: [FileResource: Set<FileSource>], unusedResources: Set<FileResource>)
