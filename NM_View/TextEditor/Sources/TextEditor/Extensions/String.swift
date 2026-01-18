//
//  String.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/6/25.
//

import Foundation

extension String {
    public func char(at intIndex: Int) -> Character? {
        // Guard against out-of-bounds and negative indices
        guard intIndex >= 0 && intIndex < self.count else { return nil }
        let idx = self.index(self.startIndex, offsetBy: intIndex)
        return self[idx]
    }
    
    public func isNextNewLine(after intIndex: Int) -> Bool {
        let next = intIndex + 1
        guard next >= 0 && next < self.count else { return false }
        
        let idx = self.index(self.startIndex, offsetBy: next)
        let ch = self[idx]
        
        return ch == "\n"
    }
}
