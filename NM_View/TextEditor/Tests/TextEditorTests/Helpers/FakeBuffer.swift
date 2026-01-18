import AppKit
@testable import TextEditor

final class FakeBuffer: BufferView {
    
    
    var onUpdateInsertionPoint: (() -> Void)?
    
    
    // MARK: - Stored state
    
    var lines: [String]
    var selection: NSRange
    var visualAnchorOffset: Int?
    private weak var textView: NSTextView?
    
    // MARK: - Init
    
    func isOnNewLine(_ pos: Position) -> Bool {
        if let c = char(at: pos) {
            if ClassifierChar.init(from: c) == .newline {
                return true
            }
        }
        return false
    }

    init(lines: [String], cursor: Position, visualAnchorOffset: Int? = nil) {
        self.lines = lines
        self.visualAnchorOffset = visualAnchorOffset
        // Calculate initial offset
        let offset = Self.offset(for: cursor, in: lines)
        self.selection = NSRange(location: offset, length: 0)
    }
    
    // MARK: - BufferView Implementation
    
    func setTextView(_ textView: NSTextView) {
        self.textView = textView
    }
    
    func updateInsertionPoint() { /* no-op for tests */ }
    
    func exitVisualMode() {
        selection.length = 0
        visualAnchorOffset = nil
    }
    
    func updateCursorAndSelectLine(anchor: Int?, to newCursor: Int) {
        visualAnchorOffset = anchor
        let maxLen = Self.totalLength(of: lines)
        
        // Clamp cursor within buffer bounds
        let safeCursor = min(max(newCursor, 0), maxLen)
        
        guard let anchor else {
            // No visual anchor → just move cursor
            selection = NSRange(location: safeCursor, length: 0)
            return
        }
        
        let safeAnchor = min(max(anchor, 0), maxLen)
        
        // Helper: given a flat offset, find the full line range [start, end)
        func lineRange(for offset: Int) -> (start: Int, end: Int) {
            var currentOffset = 0
            
            for (idx, line) in lines.enumerated() {
                // Each line = its chars + 1 newline, except maybe last line
                let lineLength = line.count + (idx < lines.count - 1 ? 1 : 0)
                let lineStart = currentOffset
                let lineEnd = currentOffset + lineLength

                let isLastLine = idx == lines.count - 1
                let isWithinLine = offset >= lineStart && offset < lineEnd
                let isEOFOnLastLine = isLastLine && offset <= lineEnd

                if isWithinLine || isEOFOnLastLine {
                    // Treat offsets at a newline as belonging to the next line.
                    return (start: lineStart, end: lineEnd)
                }
                
                currentOffset = lineEnd
            }
            
            // Fallback: whole buffer
            return (start: 0, end: maxLen)
        }
        
        let anchorLine = lineRange(for: safeAnchor)
        let headLine   = lineRange(for: safeCursor)
        
        let start = min(anchorLine.start, headLine.start)
        let end   = max(anchorLine.end,   headLine.end)
        
        let length = max(0, end - start)
        selection = NSRange(location: start, length: length)
    }

    
    func updateCursorAndSelection(anchor: Int?, to newCursor: Int) {
        visualAnchorOffset = anchor
        let maxLen = Self.totalLength(of: lines)
        // 1. Safety Clamp (same as Adapter)
        let safeCursor = min(max(newCursor, 0), maxLen)
        
        guard let anchor else {
            selection = NSRange(location: safeCursor, length: 0)
            return
        }
        
        // 2. Visual Mode Range Calculation
        let start = min(anchor, safeCursor)
        let end = max(anchor, safeCursor)
        let length = end - start + 1 // Inclusive
        
        selection = NSRange(location: start, length: length)
    }
    
    func currentVisualHead(anchor: Int?) -> Position? {
        guard let anchor else { return nil }
        let start = selection.location
        let endExclusive = selection.location + selection.length
        
        if start == anchor {
            // Forward: Head is at end - 1
            let headOffset = max(start, endExclusive - 1)
            return Self.position(for: headOffset, in: lines)
        }
        // Backward: Head is at start
        return Self.position(for: start, in: lines)
    }
    
    func cursorOffset() -> Int {
        selection.location
    }
    
    func getCursorPosition() -> NSRange? {
        selection
    }
    
    func cursorPosition() -> Position {
        if selection.length > 0, let anchor = visualAnchorOffset,
           let head = currentVisualHead(anchor: anchor) {
            return head
        }
        return Self.position(for: selection.location, in: lines)
    }
    
    func lineCount() -> Int {
        lines.count
    }
    
    // MATCHING LOGIC: NSTextView usually returns the string including the newline
    func line(at index: Int) -> String {
        guard index >= 0, index < lines.count else { return "" }
        let rawLine = lines[index]
        
        // If it's the last line, it might not have a newline.
        // For all others, we simulate the structure of NSTextView's "enclosingRange"
        if index < lines.count - 1 {
            return rawLine + "\n"
        }
        return rawLine
    }
    
    // MATCHING LOGIC: Handle the "virtual" newline character
    func char(at pos: Position) -> Character? {
        guard pos.line >= 0, pos.line < lines.count else { return nil }
        let lineStr = lines[pos.line]
        
        // If column is exactly the length, it's the newline (unless it's the very last line without one)
        if pos.column == lineStr.count {
            if pos.line < lines.count - 1 { return "\n" }
            return nil // End of file
        }
        
        guard pos.column >= 0, pos.column < lineStr.count else { return nil }
        let idx = lineStr.index(lineStr.startIndex, offsetBy: pos.column)
        return lineStr[idx]
    }
    
    // MATCHING LOGIC: Implement the "Vim clamp" (Stop BEFORE newline)
    func moveTo(position: Position) {
        guard position.line < lines.count else { return }
        
        let targetLine = lines[position.line]
        let lineLen = targetLine.count
        
        // In your real adapter, you check if lastChar == "\n" -> lineEndIndex -= 1.
        // Here, our strings don't have \n stored, so `lineLen` IS the index of the newline.
        // We clamp to `lineLen` normally, but if we want to avoid sitting ON the newline (Vim style),
        // we clamp to `lineLen - 1` if the line isn't empty.
        
        var effectiveLimit = lineLen
        
        // Mimic: "if line ends with newline, stop before it"
        // Since our array implies newlines exist between indices:
        if position.line < lines.count - 1 {
            effectiveLimit = max(0, lineLen) // Actually, vim allows sitting on the last char, which is index lineLen-1.
            // The real adapter logic: `let finalIndex = min(desiredIndex, lineEndIndex)`
            // where lineEndIndex was decremented.
        }
        
        // Note: Real adapter allows going to end of file line if no newline exists.
        
        let col = min(position.column, effectiveLimit)
        
        // Re-calculate offset
        let offset = Self.offset(for: Position(line: position.line, column: col), in: lines)
        selection = NSRange(location: offset, length: 0)
    }
    
    // MARK: - Movement
    
    func moveLeft() {
        guard selection.location > 0 else { return }
        selection.location -= 1
        selection.length = 0
    }
    
    func moveRight() {
        let maxOffset = Self.totalLength(of: lines)
        guard selection.location < maxOffset else { return }
        selection.location += 1
        selection.length = 0
    }
    
    func moveToEndOfLine() {
        let pos = cursorPosition()
        guard pos.line < lines.count else { return }
        // Move to the last character, not the newline
        let col = max(0, lines[pos.line].count)
        moveTo(position: Position(line: pos.line, column: col))
    }
    
    func moveToBottomOfFile() {
        guard let lastIndex = lines.indices.last else { return }
        let col = lines[lastIndex].count
        moveTo(position: Position(line: lastIndex, column: col))
    }
    
    func moveToTopOfFile() {
        moveTo(position: Position(line: 0, column: 0))
    }
    
    func moveDownAndStartOfLine() {
        let pos = cursorPosition()
        let newLine = pos.line + 1
        guard newLine < lines.count else { return }
        moveTo(position: Position(line: newLine, column: 0))
    }
    
    // MARK: - Helpers
    
    private static func offset(for pos: Position, in lines: [String]) -> Int {
        var offset = 0
        for i in 0..<min(pos.line, lines.count) {
            offset += lines[i].count + 1 // +1 for "\n"
        }
        // Careful not to overflow if line is invalid
        if pos.line < lines.count {
            offset += min(pos.column, lines[pos.line].count + 1)
        }
        return offset
    }
    
    private static func position(for offset: Int, in lines: [String]) -> Position {
        var remaining = offset
        for (lineIndex, line) in lines.enumerated() {
            let lineLen = line.count
            // +1 includes the newline
            if remaining <= lineLen {
                return Position(line: lineIndex, column: remaining)
            }
            remaining -= (lineLen + 1)
        }
        // End of file
        if let last = lines.indices.last {
            return Position(line: last, column: lines[last].count)
        }
        return Position(line: 0, column: 0)
    }
    
    
    func getString() -> NSString? {
        // Join lines with '\n' to match how offset/position logic is written
        let full = lines.joined(separator: "\n")
        return full as NSString
    }
    
    func deleteBeforeCursor() {
        guard let string = getString() else { return }
        
        let totalLength = string.length
        var currentRange = selection
        
        // Clamp currentRange.location into [0, totalLength]
        if currentRange.location < 0 {
            currentRange.location = 0
        } else if currentRange.location > totalLength {
            currentRange.location = totalLength
        }
        
        // If we have a selection (Visual Mode), behave like your real deleteBeforeCursor:
        // it calls deleteUnderCursor (i.e. deletes the selection via that path)
        if currentRange.length > 0 {
            deleteUnderCursor()
            return
        }
        
        // Need at least 1 char behind cursor
        guard currentRange.location > 0 else { return }
        
        // If we’re “past the end” do nothing (matches your real guard)
        if currentRange.location >= totalLength { return }
        
        // Vim-ish extra rules you have in the real implementation:
        // - don’t delete when at column 0
        // - don’t delete a newline (backspacing across lines disabled)
        let current = cursorPosition()              // your fake should have this
        if current.column == 0 { return }
        
        let lineStr = line(at: current.line)        // your fake should have this
        if let c = lineStr.char(at: current.column), c == "\n" {
            return
        }
        
        // Delete composed char sequence *before* cursor
        let rangeToDelete = string.rangeOfComposedCharacterSequence(at: currentRange.location - 1)
        
        // Copy deleted text (so "X"/"x" behavior stays consistent with your fake)
        copyToClipboard(text: string.substring(with: rangeToDelete))
        
        // Apply the deletion + put cursor at deletion start
        let newString = string.replacingCharacters(in: rangeToDelete, with: "") as NSString
        applyString(newString, newCursorLocation: rangeToDelete.location)
    }
    
    func copyToClipboard(text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    func deleteUnderCursor() {
        guard let string = getString() else { return }
        
        let totalLength = string.length
        var currentRange = selection
        
        // Clamp currentRange.location into [0, totalLength]
        if currentRange.location < 0 {
            currentRange.location = 0
        } else if currentRange.location > totalLength {
            currentRange.location = totalLength
        }
        
        // 1. If we have a selection (Visual Mode), delete the selection.
        if currentRange.length > 0 {
            let maxEnd = min(currentRange.location + currentRange.length, totalLength)
            let safeRange = NSRange(location: currentRange.location,
                                    length: maxEnd - currentRange.location)
            
            let newString = string.replacingCharacters(in: safeRange, with: "") as NSString
            applyString(newString, newCursorLocation: safeRange.location)
            return
        }
        
        // 2. If we are at the very end of the file, do nothing.
        if currentRange.location >= totalLength {
            return
        }
        
        // 3. Compute the composed character range to delete
        let rangeToDelete = string.rangeOfComposedCharacterSequence(at: currentRange.location)
        
        let newString = string.replacingCharacters(in: rangeToDelete, with: "") as NSString
        applyString(newString, newCursorLocation: rangeToDelete.location)
    }
    
    func paste() {
        guard let clip = NSPasteboard.general.string(forType: .string),
              let string = getString() else { return }
        
        // Normalize CRLF -> LF
        let normalized = clip.replacingOccurrences(of: "\r\n", with: "\n")
        
        let totalLength = string.length
        var range = selection
        
        // Clamp selection into bounds
        if range.location < 0 {
            range.location = 0
        } else if range.location > totalLength {
            range.location = totalLength
        }
        
        if range.length > 0 {
            let maxEnd = min(range.location + range.length, totalLength)
            let safeRange = NSRange(
                location: range.location,
                length: maxEnd - range.location
            )
            
            let newString = string.replacingCharacters(
                in: safeRange,
                with: normalized
            ) as NSString
            
            applyString(
                newString,
                newCursorLocation: safeRange.location + (normalized as NSString).length
            )
        } else {
            let insertRange = NSRange(location: range.location, length: 0)
            
            let newString = string.replacingCharacters(
                in: insertRange,
                with: normalized
            ) as NSString
            
            applyString(
                newString,
                newCursorLocation: insertRange.location + (normalized as NSString).length
            )
        }
    }

    // MARK: - Private helper
    
    private func applyString(_ newString: NSString, newCursorLocation: Int) {
        // Re-split into lines to keep FakeBuffer’s model in sync
        let asSwift = newString as String
        self.lines = asSwift.components(separatedBy: "\n")
        
        // Clamp cursor into new bounds
        let clampedLocation = max(0, min(newCursorLocation, newString.length))
        self.selection = NSRange(location: clampedLocation, length: 0)
        // visualAnchorOffset is left as-is; with length = 0 it won't affect cursorPosition()
    }


    private static func totalLength(of lines: [String]) -> Int {
        guard !lines.isEmpty else { return 0 }
        // chars + (newlines between lines)
        return lines.reduce(0) { $0 + $1.count } + (lines.count - 1)
    }
}
