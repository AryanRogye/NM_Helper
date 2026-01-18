//
//  NSTextViewBufferAdapter.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/7/25.
//

import AppKit

@MainActor
public final class NSTextViewBufferAdapter: BufferView {
    weak var textView: NSTextView?
    
    public var onUpdateInsertionPoint: (() -> Void)?
    
    public func setTextView(_ textView: NSTextView) {
        self.textView = textView
    }

    public func moveTo(position: Position) {
        guard let textView = textView else { return }
        let string = textView.string as NSString
        let totalLength = string.length

        var currentLine = 0
        var charIndex = 0

        /// 1. Find the Start Index of the Target Line
        /// We assume your 'Position.line' is 0-indexed.
        while currentLine < position.line && charIndex < totalLength {
            // lineRange(for:) gives us the full range of the line including the newline
            let range = string.lineRange(for: NSRange(location: charIndex, length: 0))
            charIndex = NSMaxRange(range)
            currentLine += 1
        }

        /// 2. Calculate Target Index with Column
        /// Now 'charIndex' is at the start of the correct line.
        let lineRange = string.lineRange(for: NSRange(location: charIndex, length: 0))

        // Check if the line actually has a newline character at the end so we don't skip it
        var lineEndIndex = NSMaxRange(lineRange)

        // If the line ends with a newline, we usually want the cursor to stop BEFORE it
        // unless you specifically want to allow the cursor to wrap.
        // Vim-like behavior: clamp to the last character, not the newline.
        if lineEndIndex > 0 {
            let lastCharRange = NSRange(location: lineEndIndex - 1, length: 1)
            if lastCharRange.location < totalLength {
                let lastChar = string.substring(with: lastCharRange)
                if lastChar == "\n" || lastChar == "\r" {
                    lineEndIndex -= 1
                }
            }
        }

        // Add column, but clamp so we don't go past the end of the line
        let desiredIndex = charIndex + position.column
        let finalIndex = min(desiredIndex, lineEndIndex)

        /// 3. Apply Selection
        textView.setSelectedRange(NSRange(location: finalIndex, length: 0))
        textView.scrollRangeToVisible(NSRange(location: finalIndex, length: 0))
    }

    public func getCursorPosition() -> NSRange? {
        guard let textView else { return nil }
        return textView.selectedRange
    }

    /// Calculates the actual position of the "moving" cursor (The Head).
    /// In NSTextView, `selectedRange.location` is always the start (left side).
    /// We need to know if we are selecting forwards or backwards to find the real head.
    public func currentVisualHead(anchor: Int?) -> Position? {
        guard let anchor, let textView else { return nil }
        
        let range = textView.selectedRange
        let start = range.location
        let endExclusive = range.location + range.length
        let endInclusive = max(start, endExclusive - 1)
        
        // If anchor is the start of the normalized range, head is the end.
        if anchor == start {
            return cursorOffsetToPosition(endInclusive)
        }
        
        // If anchor is the end, head is the start.
        if anchor == endInclusive {
            return cursorOffsetToPosition(start)
        }
        
        // Fallback: anchor is "inside" (can happen if text changed).
        // Pick whichever end is farther from anchor (keeps direction consistent).
        let head = (abs(endInclusive - anchor) >= abs(anchor - start)) ? endInclusive : start
        return cursorOffsetToPosition(head)
    }
    
    public func deleteRange(_ range: NSRange) {
        guard let textView else { return }
        textView.insertText("", replacementRange: range)
    }
    
    public func getString() -> NSString? {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return nil }
        return textStorage.string as NSString
    }
    
    
    public func getPasteboard() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
    
    func copyToClipboard(text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
    
    public func deleteBeforeCursor() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let currentRange = textView.selectedRange
        let string = textStorage.string as NSString
        let totalLength = string.length
        
        /// If we have a selection (Visual Mode), delete under cursor "X"
        /// `X` should not do this
        if currentRange.length > 0 {
            deleteUnderCursor()
            return
        }
        guard currentRange.location > 0 else { return }
        
        if currentRange.location >= totalLength {
            return
        }
        
        let current = cursorPosition()
        let c = line(at: current.line).char(at: current.column)
        if current.column == 0 { return }
        if c == "\n" { return }
        
        // 3. Calculate the range to delete.
        // We use 'rangeOfComposedCharacterSequence' to ensure we don't break
        // Emojis or special characters that take up more than 1 UTF-16 index.
        let rangeToDelete = string.rangeOfComposedCharacterSequence(at: currentRange.location - 1)
        
        // 4. Perform the deletion via the Input Manager (preserves Undo history).
        copyToClipboard(text: string.substring(with: rangeToDelete))
        textView.insertText("", replacementRange: rangeToDelete)
    }

    public func deleteUnderCursor() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let currentRange = textView.selectedRange
        let string = textStorage.string as NSString
        let totalLength = string.length
        
        // 1. If we have a selection (Visual Mode), delete the selection.
        if currentRange.length > 0 {
            copyToClipboard(text: string.substring(with: currentRange))
            textView.insertText("", replacementRange: currentRange)
            return
        }
        
        // 2. Bounds Check: If we are at the very end of the file, do nothing.
        if currentRange.location >= totalLength {
            return
        }
        
        let current = cursorPosition()
        let c = line(at: current.line).char(at: current.column)
        if c == "\n" { return }

        // 3. Calculate the range to delete.
        // We use 'rangeOfComposedCharacterSequence' to ensure we don't break
        // Emojis or special characters that take up more than 1 UTF-16 index.
        let rangeToDelete = string.rangeOfComposedCharacterSequence(at: currentRange.location)
        
        // 4. Perform the deletion via the Input Manager (preserves Undo history).
        copyToClipboard(text: string.substring(with: rangeToDelete))
        textView.insertText("", replacementRange: rangeToDelete)
    }
    
    public func paste() {
        guard let textView = textView,
              let textStorage = textView.textStorage,
              var clip = getPasteboard() else { return }
        
        let string = textStorage.string as NSString
        
        // Normalize CRLF → LF so content is consistent
        clip = clip.replacingOccurrences(of: "\r\n", with: "\n")
        
        let sel = textView.selectedRange
        let selectedText = string.substring(with: sel)
        
        /// Only if something is selected copy it
        if sel.length > 0 {
            /// Copy
            copyToClipboard(text: selectedText)
        }
        
        // Vim-like rule: selection gets replaced
        textView.insertText(clip, replacementRange: sel)
    }

    private func cursorOffsetToPosition(_ offset: Int?) -> Position? {
        guard let offset else { return nil }
        guard let textView,
              let textStorage = textView.textStorage else {
            return Position(line: 0, column: 0)
        }

        let text = textStorage.string as NSString
        let clampedOffset = min(max(offset, 0), text.length)

        var line = 0
        var lineStart = 0

        text.enumerateSubstrings(
            in: NSRange(location: 0, length: text.length),
            options: .byLines
        ) { _, range, _, stop in

            let lineEnd = NSMaxRange(range)

            if clampedOffset >= range.location && clampedOffset <= lineEnd {
                lineStart = range.location
                stop.pointee = true
                return
            }

            line += 1
        }

        let column = clampedOffset - lineStart
        return Position(line: line, column: column)
    }

    public func cursorOffset() -> Int {
        guard let textView else { return 0 }
        return textView.selectedRanges.first?.rangeValue.location ?? 0
    }
    
    public func isOnNewLine(_ pos: Position) -> Bool {
        if let c = char(at: pos) {
            if ClassifierChar.init(from: c) == .newline {
                return true
            }
        }
        return false
    }

    public func cursorPosition() -> Position {
        /// if no textView return 0,0
        guard let textView else {
            return Position(line: 0, column: 0)
        }
        guard let textStorage = textView.textStorage else { return Position(line: 0, column: 0) }

        let cursorPosition = textView.selectedRanges[0].rangeValue.location
        let text = textStorage.string as NSString

        var lineCount = 0

        // Iterate through each line by finding newlines
        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length),
                                 options: .byLines) { _, substringRange, _, stop in
            if cursorPosition >= substringRange.location && cursorPosition <= NSMaxRange(substringRange) {
                stop.pointee = true
                return
            }
            lineCount += 1
        }

        // Calculate column for the found line
        var lineStartIndex = 0
        var currentLine = 0
        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length),
                                 options: .byLines) { _, substringRange, _, stop in
            if currentLine == lineCount {
                lineStartIndex = substringRange.location
                stop.pointee = true
            }
            currentLine += 1
        }

        let column = cursorPosition - lineStartIndex
        return Position(line: lineCount, column: column)
    }

    public func lineCount() -> Int {
        guard let textView else { return 0 }
        guard let textStorage = textView.textStorage else { return 0 }

        let text = textStorage.string as NSString
        var count = 0

        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length),
                                 options: .byLines) { _, _, _, _ in
            count += 1
        }

        return count
    }

    public func char(at pos: Position) -> Character? {
        guard let textView else { return nil }
        guard let textStorage = textView.textStorage else { return nil }

        let text = textStorage.string as NSString
        let row = pos.line
        let col = pos.column

        var currentLine = 0
        var result: Character? = nil

        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length),
                                 options: .byLines) { _, substringRange, enclosingRange, stop in
            if currentLine == row {
                // Calculate the absolute position in the text
                let charPosition = substringRange.location + col

                // Check if column is within bounds of this line
                if charPosition < NSMaxRange(enclosingRange) && charPosition < text.length {
                    let char = text.character(at: charPosition)
                    result = Character(UnicodeScalar(char)!)
                }
                stop.pointee = true
            }
            currentLine += 1
        }

        return result
    }

    public func line(at index: Int) -> String {
        guard let textView else { return "" }
        guard let textStorage = textView.textStorage else { return "" }

        let text = textStorage.string as NSString
        var currentLine = 0
        var result = ""

        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length),
                                 options: .byLines) { substring, substringRange, enclosingRange, stop in
            if currentLine == index {
                // Use enclosingRange to include the newline character
                result = text.substring(with: enclosingRange)
                stop.pointee = true
            }
            currentLine += 1
        }

        return result
    }

    public func updateInsertionPoint() {
        guard let textView else { return }
        textView.updateInsertionPointStateAndRestartTimer(true)
        onUpdateInsertionPoint?()
    }

    public func exitVisualMode() {
        guard let textView else { return }

        let cursor = textView.selectedRange.location
        let range = NSRange(location: cursor, length: 0)

        textView.setSelectedRange(range)
    }

    public func updateCursorAndSelectLine(anchor: Int?, to newCursor: Int) {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let totalLength = textStorage.length
        let nsString = textStorage.string as NSString
        
        // Safety clamp
        let safeCursor = min(max(newCursor, 0), totalLength)
        
        guard let anchor = anchor else {
            // No visual anchor – just move cursor
            textView.setSelectedRange(NSRange(location: safeCursor, length: 0))
            return
        }
        
        let safeAnchor = min(max(anchor, 0), totalLength)
        
        // Get full line ranges (including trailing newline) for anchor + head
        let anchorLineRange = nsString.lineRange(for: NSRange(location: safeAnchor, length: 0))
        let headLineRange   = nsString.lineRange(for: NSRange(location: safeCursor, length: 0))
        
        // Start at the first line's start
        let start = min(anchorLineRange.location, headLineRange.location)
        // End at the end of the last line (exclusive)
        let end   = max(NSMaxRange(anchorLineRange), NSMaxRange(headLineRange))
        
        // Clamp end to totalLength just in case
        let clampedEnd = min(end, totalLength)
        let length = max(0, clampedEnd - start)
        
        textView.setSelectedRange(NSRange(location: start, length: length))
    }
    
    public func getSelectedRange(anchor: Int?) -> PositionRange? {
        guard let textView = textView,
              let storage = textView.textStorage else { return nil }
        
        let text = storage.string as NSString
        let cursor = textView.selectedRange.location
        
        // not in visual mode -> just caret as both ends
        guard let anchor else {
            let p = position(at: cursor, in: text)
            return (p, p)
        }
        
        let startIndex = min(anchor, cursor)
        let endIndex   = max(anchor, cursor)
        
        let startPos = position(at: startIndex, in: text)
        let endPos   = position(at: endIndex, in: text)
        
        return (startPos, endPos)
    }
    private func position(at index: Int, in text: NSString) -> Position {
        let safe = min(max(index, 0), text.length)
        
        var line = 0
        var lineStart = 0
        
        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length), options: .byLines) {
            _, r, _, stop in
            // r is the line range (without newline)
            if safe <= NSMaxRange(r) {
                lineStart = r.location
                stop.pointee = true
                return
            }
            line += 1
        }
        
        let column = safe - lineStart
        return Position(line: line, column: column)
    }
    
    public func updateCursorAndSelection(anchor: Int?, to newCursor: Int) {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }

        let totalLength = textStorage.length

        /// 1. Safety Clamp: Ensure cursor never reports outside valid string bounds
        let safeCursor = min(max(newCursor, 0), totalLength)

        guard let anchor = anchor else {
            // Not in visual mode – just move cursor (length 0)
            textView.setSelectedRange(NSRange(location: safeCursor, length: 0))
            return
        }

        /// 2. Calculate Min/Max for the range
        let start = min(anchor, safeCursor)
        let end   = max(anchor, safeCursor)

        /// 3. Calculate Length (Inclusive)
        /// Vim Visual mode is inclusive, so we add +1 to include the character at 'end'.
        var length = end - start + 1

        /// 4. Final Bounds Check
        /// If the calculation tries to select past the end of the file (e.g. cursor is at EOF),
        /// we must clamp the length so we don't crash.
        if start + length > totalLength {
            length = totalLength - start
        }

        /// 5. Apply
        if length > 0 {
            textView.setSelectedRange(NSRange(location: start, length: length))
        } else {
            /// Fallback for edge cases (like empty file)
            textView.setSelectedRange(NSRange(location: start, length: 0))
        }
    }

    public func moveToBottomOfFile() {
        guard let textView = textView else { return }
        textView.moveToEndOfDocument(textView)
    }
    public func moveToTopOfFile() {
        guard let textView = textView else { return }
        textView.moveToBeginningOfDocument(textView)
    }
    public func moveDownAndStartOfLine() {
        guard let textView = textView else { return }
        textView.moveDown(textView)
        textView.moveToBeginningOfLine(textView)
    }
}
