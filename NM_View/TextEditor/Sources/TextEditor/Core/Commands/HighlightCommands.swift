//
//  HighlightCommands.swift
//  TextEditor
//
//  Created by Aryan Rogye on 1/19/26.
//

import AppKit

@MainActor
public protocol HighlightCommands: AnyObject {
    func gotoHighlight(_ index: Int)
    func gotoHighlight(_ range: NSRange)
    func resetHighlightedRanges()
}
