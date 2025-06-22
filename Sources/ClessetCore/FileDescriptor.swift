//
//  FileDescriptor.swift
//  Clesset
//
//  Created by Vladyslav Kocherhin on 02.06.2025.
//
//  This software is released under the MIT License.
//  https://opensource.org/licenses/MIT
//

import Foundation
import Darwin

struct FileDescriptor: Sendable {
    
    let size: Int
    let pointer: RawPointerBox
    
    private let fd: Int32
    
    init?(path: String) {
        fd = Darwin.open(path, Darwin.O_RDONLY)
        size = Int(Darwin.lseek(fd, 0, Darwin.SEEK_END))
        
        guard let pointer = Darwin.mmap(nil, size, Darwin.PROT_READ, Darwin.MAP_FILE | Darwin.MAP_PRIVATE, fd, 0) else {
            return nil
        }
        
        self.pointer = RawPointerBox(
            ptr: pointer.bindMemory(to: UInt8.self, capacity: size)
        )
    }
    
    func close() {
        Darwin.close(fd)
    }
    
}

extension FileDescriptor {
    
    struct RawPointerBox: @unchecked Sendable {
        
        let ptr: UnsafeMutablePointer<UInt8>
        
    }
    
}
