//
//  Up.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import Testing
@testable import TextEditor

extension TextEditorTests {
    
    @Test
    func movesUpBetweenNewLinesVisualLine() {
        let buffer = FakeBuffer(
            lines: [
                "TESTING",
                "",
                "",
                "TESTING"
            ],
            cursor: Position(line: 3, column: 0)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .visualLine
        vimEngine.visualAnchorLocation = buffer.cursorOffset()
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos.line == 0)
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 0)
        #expect(selection?.length == 17)
    }
    
    @Test
    func movesUpBetweenNewLinesVisual() {
        let buffer = FakeBuffer(
            lines: [
                "TESTING",
                "",
                "",
                "TESTING"
            ],
            cursor: Position(line: 3, column: 0)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .visual
        vimEngine.visualAnchorLocation = buffer.cursorOffset()
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos.line == 0)
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 0)
        #expect(selection?.length == 11)
    }
    
    @Test
    func movesUpBetweenNewlines() {
        let buffer = FakeBuffer(
            lines: [
                "TESTING",
                "",
                "",
                "TESTING"
            ],
            cursor: Position(line: 3, column: 0)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos.line == 0)
    }
    
    @Test
    func testBasicMoveUp() {
        let buffer = FakeBuffer(
            lines: [
                "First line",
                "Second line",
                "Third line"
            ],
            cursor: Position(line: 2, column: 0)
        )
        
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        
        let newCursorPos = buffer.cursorPosition()
        print(newCursorPos)
        
        #expect(newCursorPos.line == 1)
        #expect(newCursorPos.column == 0)
    }
    
    @Test
    func testMoveUpClampsToShorterLine() {
        // Scenario: Moving from long line -> short line
        let buffer = FakeBuffer(
            lines: [
                "Short",
                "Longer line"
            ],
            cursor: Position(line: 1, column: 10) // End of "Longer line"
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        
        let newCursor = buffer.cursorPosition()
        
        // Should clamp to end of "Short" (index 4)
        #expect(newCursor.line == 0)
        #expect(newCursor.column == 4)
    }
    
    @Test
    func testMoveUpPreservesColumn() {
        // Scenario: Moving from short line -> long line (or equal)
        let buffer = FakeBuffer(
            lines: ["Longer line", "Short"],
            cursor: Position(line: 1, column: 2) // Middle of "Short"
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        
        let newCursor = buffer.cursorPosition()
        
        // Should stay at column 2
        #expect(newCursor.line == 0)
        #expect(newCursor.column == 2)
    }
    
    @Test
    func testStickColumnComplicated() {
        var longLine = "func textViewDidChangeSelection(_ notification: Notification)"
        let shortLine = "//"
        let start = Position(line: 2, column: 5)
        let char  = longLine.char(at: start.column)
        
        let buffer = FakeBuffer(
            lines: [
                longLine,
                shortLine,
                longLine
            ],
            cursor: start
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        /// Move Up 2 times
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        
        let cursorPos = buffer.cursorPosition()
        let line      = buffer.line(at: cursorPos.line)
        
        longLine += "\n"
        
        #expect(line == longLine)
        #expect(cursorPos.column == start.column)
        #expect(line.char(at: cursorPos.column) == char)
    }
    
    @Test
    func testStickyColumnMemoryUp() {
        let longLine = "A very long line of text" // Length 24
        let shortLine = "Short"                  // Length 5
        
        let buffer = FakeBuffer(
            lines: [
                longLine,   // Line 0
                shortLine,  // Line 1
                longLine    // Line 2
            ],
            // Start at the end of the last line (col 24)
            cursor: Position(line: 2, column: longLine.count)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        // 1. Move UP to the short line
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        var cursorPos = buffer.cursorPosition()
        var line      = buffer.line(at: cursorPos.line)
        
        // It should clamp to the end of "Short"
        #expect(cursorPos.line == 1)
        #expect(cursorPos.column == shortLine.count - 1)
        #expect(line.char(at: cursorPos.column) == "t")
        
        // 2. Move UP again to the long line
        vimEngine.handleVimEvent(Util.makeKeyEvent("k"))
        cursorPos = buffer.cursorPosition()
        line      = buffer.line(at: cursorPos.line)
        
        // CRITICAL CHECK: It should remember we wanted column 24
        // If it fails, it will likely equal 5 (shortLine.count)
        #expect(cursorPos.line == 0)
        #expect(cursorPos.column == longLine.count - 1)
        #expect(line.char(at: cursorPos.column) == "t")
    }
}
