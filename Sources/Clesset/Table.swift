//
//  Table.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 24.06.2025.
//

struct Table {
    let rows: [Row]
}

extension Table {
    struct Row {
        let resource: String
        let size: String
        let files: [String]
    }
    
    enum Colum: String, Identifiable, CaseIterable {
        case resource = "Resource"
        case size = "Size(bytes)"
        case files = "Found at"
        
        var id: UInt8 {
            switch self {
            case .resource:
                return 0
            case .size:
                return 1
            case .files:
                return 2
            }
        }
    }
    
    func draw() -> String {
        var result = ""
        
        let columSize = rows.reduce(into: [Table.Colum: Int]()) {
            $0[.resource] = max(max($1.resource.count, Table.Colum.resource.rawValue.count), $0[.resource] ?? .zero)
            $0[.size] = max(max($1.size.count, Table.Colum.size.rawValue.count), $0[.size] ?? .zero)
            $0[.files] = max(max($1.files.map { $0.count }.max() ?? .zero, Table.Colum.files.rawValue.count), $0[.files] ?? .zero)
        }
        
        let header = "┌" + columSize.sorted(by: { $0.key.id < $1.key.id }).map { String(repeating: "─", count: $0.value + 2) }.joined(separator: "┬") + "┐"
        let separator = "├" + columSize.sorted(by: { $0.key.id < $1.key.id }).map { String(repeating: "─", count: $0.value + 2) }.joined(separator: "┼") + "┤"
        let bottom = "└" + columSize.sorted(by: { $0.key.id < $1.key.id }).map { String(repeating: "─", count: $0.value + 2) }.joined(separator: "┴") + "┘"
        
        func box(for value: String, length: Int) -> String {
            return value + String(repeating: " ", count:  max(.zero, length - value.count))
        }
        
        result += header
        result += "\n| \(columSize.sorted(by: { $0.key.id < $1.key.id }).map { box(for: $0.key.rawValue, length: $0.value) }.joined(separator: " | ")) |"
        result += "\n\(separator)"
        
        rows.enumerated().forEach { row in
            row.element.files.enumerated().forEach {
                let resource = $0.offset == .zero ? row.element.resource : ""
                let size = $0.offset == .zero ? row.element.size : ""
                result += "\n| \(box(for: resource, length: columSize[.resource] ?? .zero)) | \(box(for: size, length: columSize[.size] ?? .zero)) | \(box(for: $0.element, length: columSize[.files] ?? .zero)) |"
            }
            
            if row.offset != rows.count - 1 {
                result += "\n\(separator)"
            }
        }
        
        result += "\n\(bottom)"
        return result
    }
    
}
