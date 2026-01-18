//
//  BottomStatusModel.swift
//  TextEditor
//
//  Created by Aryan Rogye on 1/18/26.
//

import Foundation

@Observable
@MainActor
final class BottomStatusModel {
    var indices: [Int] = []
    
    var updateHighlightedRanges: ((NSRange) -> Void) = { range in }
    var resetHighlightedRanges: () -> Void = { }
    
    func rangeFor(index: Int) -> NSRange {
        return NSRange(location: index, length: 1)
    }
    
    public func highlight(_ index: Int) {
        let r = rangeFor(index: index)
        updateHighlightedRanges(r)
    }
}
