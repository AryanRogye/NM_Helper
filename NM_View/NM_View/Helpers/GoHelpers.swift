//
//  GoHelpers.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/18/26.
//

import Foundation

enum GoHelpers {
    static nonisolated func goSliceToInts(_ s: GoSlice) -> [Int] {
        guard let base = s.data else { return [] }
        
        // Go int is 8 bytes on macOS (amd64/arm64)
        let ptr = base.bindMemory(to: Int64.self, capacity: Int(s.len))
        let buf = UnsafeBufferPointer(start: ptr, count: Int(s.len))
        
        return buf.map { Int($0) }  // copy into Swift memory
    }
}
