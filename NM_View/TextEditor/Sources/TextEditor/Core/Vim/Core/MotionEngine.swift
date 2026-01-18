//
//  MotionEngine.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/7/25.
//

import Foundation

@MainActor
final class MotionEngine {
    
    public init(buffer: BufferView) {
        self.buffer = buffer
    }
    var buffer: BufferView
    var stickyColumn: Int?
    
    // MARK: - Last Word Leading
    /// Function to go to the last word thats leading
    func lastWordLeading(_ currentPos: Position? = nil) -> Position {
        var currentPos : Position = currentPos ?? buffer.cursorPosition()
        
        /// Move up by 1 if at 0 index
        if currentPos.column == 0 {
            /// as long as gong back by 1 line wont crash us
            if currentPos.line > 0 {
                let lastLineIdx = currentPos.line - 1
                let lastLineStr = buffer.line(at: lastLineIdx)
                
                /// "Wrap" to the end of the previous line
                currentPos = Position(line: lastLineIdx, column: lastLineStr.count)
            }
            /// if moving back 1 line crashes us return current pos
            /// We are at 0,0 (Start of file) -> Don't move
            else {
                return currentPos
            }
        }
        
        let line       : String   = buffer.line(at: currentPos.line)
        let classified: [ClassifierChar] = ClassifierChar.line(line)
        
        if let dist = TextEngine.calcLastWordDistanceLeading(states: classified, idx: currentPos.column) {
            let newCol = currentPos.column - dist
            currentPos = Position(line: currentPos.line, column: max(0, newCol))
        }
        return currentPos
    }
    
    // MARK: - Next Word Trailing
    func nextWordTrailing(_ currentPos: Position? = nil) -> Position {
        let currentPos : Position = currentPos ?? buffer.cursorPosition()
        let line       : String   = buffer.line(at: currentPos.line)
        
        let classified = ClassifierChar.line(line)
        
        let dist = TextEngine.calcNextWordTrailingDistance(states: classified, idx: currentPos.column)
        var count = 1;
        if let dist, dist != 0 {
            count = dist
        }
        let newCol = currentPos.column + count
        if newCol >= line.count {
            return Position(line: currentPos.line + 1, column: 0)
        }
        return Position(line: currentPos.line, column: (max(0, newCol)))
    }
    
    // MARK: - Next Word Leading
    func nextWordLeading(_ currentPos: Position? = nil) -> Position {
        let currentPos : Position = currentPos ?? buffer.cursorPosition()
        let line       : String   = buffer.line(at: currentPos.line)
        
        let classified: [ClassifierChar] = ClassifierChar.line(line)
        
        let dist = TextEngine.calcNextWordLeadingDistance(states: classified, idx: currentPos.column)
        var count = 1;
        if let dist, dist != 0 {
            count = dist
        }
        var newCol = currentPos.column + count
        
        if buffer.isOnNewLine(currentPos) {
            newCol += 1
        }
        
        var pos: Position
        if newCol >= line.count {
            pos = Position(line: currentPos.line + 1, column: 0)
        } else {
            pos = Position(line: currentPos.line, column: (max(0, newCol)))
        }
        
        if buffer.isOnNewLine(pos) {
            pos = Position(line: currentPos.line + 1, column: 0)
        }
        
        return pos
    }
    
    // MARK: - Move End of Line
    public func moveToEndOfLine(_ currentPos: Position? = nil) -> Position {
        let current = currentPos ?? buffer.cursorPosition()
        let line    : String     = buffer.line(at: current.line)
        
        if line == "" { return current }
        let maxCol = line.count
        return Position(line: current.line, column: maxCol)
    }
    
    // MARK: - Move to Start of Line
    public func moveToStartOfLine(_ currentPos: Position? = nil) -> Position {
        let current = currentPos ?? buffer.cursorPosition()
        return Position(line: current.line, column: 0)
    }
    
    // MARK: - Up
    public func up(_ currentPos: Position? = nil) -> Position {
        let current = currentPos ?? buffer.cursorPosition()
        
        /// Can't move past the first line
        guard current.line > 0 else { return current }
        
        return resolveVerticalMove(
            from: current.column,
            to: current.line - 1
        )
    }
    
    // MARK: - Down
    public func down(_ currentPos: Position? = nil) -> Position {
        let current = currentPos ?? buffer.cursorPosition()
        
        /// Can't move past the last line
        guard current.line < buffer.lineCount() - 1 else { return current }
        
        let pos = resolveVerticalMove(
            from: current.column,
            to: current.line + 1
        )
        return pos
    }
    
    // MARK: - Right
    public func rightOne(_ currentPos: Position? = nil) -> Position {
        let current = currentPos ?? buffer.cursorPosition()
        
        let line = buffer.line(at: current.line)
        let maxCol = line.count - 1
        guard current.column < maxCol else { return current }
        return Position(line: current.line, column: current.column + 1)
    }
    // MARK: - Left
    public func leftOne(_ currentPos: Position? = nil) -> Position {
        let current = currentPos ?? buffer.cursorPosition()
        
        guard current.column > 0 else { return current }
        return Position(line: current.line, column: current.column - 1)
    }

    // MARK: - resolveVerticalMove
    /// Resolves vertical cursor movement (used by both `up` and `down`)
    ///
    /// Mental model:
    /// 1. We already decided WHICH line we are moving to (targetLine)
    /// 2. Now we need to resolve the horizontal column correctly
    ///
    /// Sticky column rules (Vim-like):
    /// - If the previous column is LONGER than the new line:
    ///   → remember the desired column (stickyColumn)
    ///   → clamp to the max column of the new line
    ///
    /// - If a stickyColumn already exists:
    ///   → try to restore that column (or clamp if still too short)
    ///   → clear stickyColumn once applied
    ///
    /// - Otherwise:
    ///   → just clamp the current column to the new line
    ///
    /// Final rule:
    /// - Never allow the cursor to land ON the trailing `\n`
    private func resolveVerticalMove(
        from desiredColumn: Int,
        to targetLine: Int
    ) -> Position {
        
        /// Start with the target line, column will be resolved below
        var pos = Position(line: targetLine, column: desiredColumn)
        
        /// Get the text for the target line
        var line = buffer.line(at: targetLine)
        
        
        if line.isEmpty || line == "\n" {
            pos.column = 0
            return pos
        }
        
        /// Max valid column on this line
        /// (we subtract 1 so we don't land past the content)
        let maxCol = line.count - 1
        
        /// If the column from the previous line is longer than the current line
        /// AND we haven't set a sticky column yet:
        ///
        /// - Remember the desired column
        /// - Clamp to the end of this shorter line
        if desiredColumn > maxCol, stickyColumn == nil {
            stickyColumn = desiredColumn
            pos.column = maxCol
        } else {
            /// If we already have a sticky column:
            /// - Try to restore it
            /// - Clamp if this line is still too short
            /// - Clear stickyColumn once applied
            if let stickyColumn {
                pos.column = min(stickyColumn, maxCol)
                self.stickyColumn = nil
            }
            
            /// Otherwise:
            /// - No sticky logic needed
            /// - Just clamp current column to this line
            else {
                pos.column = min(desiredColumn, maxCol)
            }
        }
        
        /// Reload line in case column changed
        line = buffer.line(at: pos.line)
        
        /// Safety check:
        /// If we somehow landed on a trailing newline character,
        /// move left by one so the cursor stays on real content
        if let c = line.char(at: pos.column),
           c == "\n",
           pos.column == line.count - 1 {
            pos.column -= 1
        }
        
        return pos
    }
}
