//
//  EditorCommands.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/24/25.
//

import AppKit

@MainActor
public protocol EditorCommands: AnyObject {
    func toggleBold()
    func increaseFontOrZoomIn()
    func decreaseFontOrZoomOut()
}

@MainActor
public protocol HighlightCommands: AnyObject {
    func gotoHighlight(_ index: Int)
    func gotoHighlight(_ range: NSRange)
    func resetHighlightedRanges()
}
