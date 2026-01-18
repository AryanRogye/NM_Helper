//
//  Buffer.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/7/25.
//
import AppKit

@MainActor
public protocol BufferView {
    
    typealias PositionRange = (Position, Position)
    
    var onUpdateInsertionPoint: (() -> Void)? { get set }
    
    func getString() -> NSString?
    func deleteBeforeCursor()
    func deleteUnderCursor()
    func paste()
    func setTextView(_ textView: NSTextView)
    func updateInsertionPoint()
    func exitVisualMode()
    func updateCursorAndSelection(anchor: Int?, to newCursor: Int)
    func updateCursorAndSelectLine(anchor: Int?, to newCursor: Int)
    func currentVisualHead(anchor: Int?) -> Position?
    func cursorOffset() -> Int
    func moveTo(position: Position)
    func getCursorPosition() -> NSRange?
    func cursorPosition() -> Position
    func isOnNewLine(_ pos: Position) -> Bool
    func lineCount() -> Int
    func line(at index: Int) -> String
    func char(at pos: Position) -> Character?
    func moveToBottomOfFile()

    func moveToTopOfFile()

    /// Represents Vim-style `w` behavior across lines.
    ///
    /// Example:
    ///
    ///     something here testing o
    ///                         ^ cursor (*HERE*)
    ///     testing something out here too
    ///
    /// Pressing `w` moves the cursor to:
    ///
    ///     something here testing o
    ///     testing something out here too
    ///     ^ cursor (*HERE*)
    /// Because next word is newline, on newline, we call our function
    /// to move down and to the start of the line
    func moveDownAndStartOfLine()
}
