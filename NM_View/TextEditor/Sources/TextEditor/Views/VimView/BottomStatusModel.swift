//
//  BottomStatusModel.swift
//  TextEditor
//
//  Created by Aryan Rogye on 1/18/26.
//

import Foundation

@Observable
@MainActor
final class HighlightModel {
    var indices: [Int] = []
    
    var updateHighlightedRanges: ((NSRange, String) -> Void) = { _, _ in }
    var resetHighlightedRanges: () -> Void = { }
    
    nonisolated func rangeFor(index: Int) -> NSRange {
        return NSRange(location: index, length: 1)
    }
    
    public func highlight(_ index: Int, filterText: String) {
        let r = rangeFor(index: index)
        updateHighlightedRanges(r, filterText)
    }
}
