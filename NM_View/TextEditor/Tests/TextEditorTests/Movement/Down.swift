//
//  Down.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import Testing
@testable import TextEditor

extension TextEditorTests {
    
    @Test
    func moveDownBetweenNewLinesVisualLine() {
        let buffer = FakeBuffer(
            lines: [
                "TESTING",
                "",
                "",
                "TESTING"
            ],
            cursor: Position(line: 0, column: 0),
            visualAnchorOffset: 0
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .visualLine
        vimEngine.visualAnchorLocation = buffer.cursorOffset()
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos.line == 3)
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 0)
        #expect(selection?.length == 17) // Spans all lines including implied newlines
    }
    
    @Test
    func moveDownBetweenNewLinesVisual() {
        let buffer = FakeBuffer(
            lines: [
                "TESTING",
                "",
                "",
                "TESTING"
            ],
            cursor: Position(line: 0, column: 0),
            visualAnchorOffset: 0
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .visual
        vimEngine.visualAnchorLocation = buffer.cursorOffset()
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos.line == 3)
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 0)
        #expect(selection?.length == 11) // Inclusive from anchor to head
    }
    
    @Test
    func movesDownBetweenNewlines() {
        let buffer = FakeBuffer(
            lines: [
                "TESTING",
                "",
                "",
                "TESTING"
            ],
            cursor: Position(line: 0, column: 0)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos.line == 3)
    }
    
    @Test
    func testBasicMoveDown() {
        let buffer = FakeBuffer(
            lines: [
                "First line",
                "Second line",
                "Third line"
            ],
            cursor: Position(line: 0, column: 0)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        
        let newCursorPos = buffer.cursorPosition()
        
        #expect(newCursorPos.line == 1)
        #expect(newCursorPos.column == 0)
    }
    
    @Test
    func testMoveDownClampsToShorterLine() {
        // Scenario: Moving from long line -> short line
        let buffer = FakeBuffer(
            lines: [
                "Longer line",
                "Short"
            ],
            cursor: Position(line: 0, column: 10) // Near end of "Longer line"
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        
        let newCursor = buffer.cursorPosition()
        
        // Should clamp to end of "Short" (index 4)
        #expect(newCursor.line == 1)
        #expect(newCursor.column == 4)
    }
    
    @Test
    func testMoveDownPreservesColumn() {
        // Scenario: Moving from short line -> long line (or equal)
        let buffer = FakeBuffer(
            lines: [
                "Short",
                "Longer line"
            ],
            cursor: Position(line: 0, column: 2) // Middle of "Short"
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        
        let newCursor = buffer.cursorPosition()
        
        // Should stay at column 2
        #expect(newCursor.line == 1)
        #expect(newCursor.column == 2)
    }
    
    @Test
    func testStickyColumnComplicatedDown() {
        var longLine = "func textViewDidChangeSelection(_ notification: Notification)"
        let shortLine = "//"
        let start = Position(line: 0, column: 5)
        let char  = longLine.char(at: start.column)
        
        let buffer = FakeBuffer(
            lines: [
                longLine,
                shortLine,
                longLine,
                shortLine
            ],
            cursor: start
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        /// Move Down 2 times
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        
        let cursorPos = buffer.cursorPosition()
        let line      = buffer.line(at: cursorPos.line)
        
        longLine += "\n"
        
        #expect(cursorPos.line == 2)
        #expect(line == longLine)
        #expect(cursorPos.column == start.column)
        #expect(line.char(at: cursorPos.column) == char)
    }
    
    @Test
    func testStickyColumnMemoryDown() {
        let longLine = "A very long line of text" // Length 24
        let shortLine = "Short"                   // Length 5
        
        let buffer = FakeBuffer(
            lines: [
                longLine,   // Line 0
                shortLine,  // Line 1
                longLine    // Line 2
            ],
            // Start at the end of the first long line (col 24)
            cursor: Position(line: 0, column: longLine.count)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        // 1. Move DOWN to the short line
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        var cursorPos = buffer.cursorPosition()
        var line      = buffer.line(at: cursorPos.line)
        
        // It should clamp to the end of "Short"
        #expect(cursorPos.line == 1)
        #expect(cursorPos.column == shortLine.count - 1)
        #expect(line.char(at: cursorPos.column) == "t")
        
        // 2. Move DOWN again to the long line
        vimEngine.handleVimEvent(Util.makeKeyEvent("j"))
        cursorPos = buffer.cursorPosition()
        line      = buffer.line(at: cursorPos.line)
        
        // It should remember we wanted the original long column
        #expect(cursorPos.line == 2)
        #expect(cursorPos.column == longLine.count - 1)
        #expect(line.char(at: cursorPos.column) == "t")
    }
}
