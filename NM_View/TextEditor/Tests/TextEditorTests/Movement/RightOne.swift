//
//  RightOne.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//
import Testing
@testable import TextEditor

extension TextEditorTests {
    @Test
    func movesRightInVisualModeExpandsSelection() {
        let buffer = FakeBuffer(
            lines: [
                "TEST"
            ],
            cursor: Position(line: 0, column: 0)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .visual
        vimEngine.visualAnchorLocation = buffer.cursorOffset()
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos == Position(line: 0, column: 2))
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 0)
        #expect(selection?.length == 3)
    }
    
    @Test
    func movesRight() {
        var cursor = Position(line: 0, column: 0)
        let buffer = FakeBuffer(
            lines: [
                "TESTING",
            ],
            cursor: cursor
        )
        #expect(buffer.cursorPosition() == cursor)
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        cursor.column += 3
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos == cursor)
    }
    
    @Test
    func movesRightNewline() {
        let line = "TESTING"
        let cursor = Position(line: 0, column: line.count)
        let buffer = FakeBuffer(
            lines: [
                line,
                "",
            ],
            cursor: cursor
        )
        #expect(buffer.cursorPosition() == cursor)
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        
        let newCursorPos = buffer.cursorPosition()
        #expect(newCursorPos == cursor)
    }
    
    @Test
    func movesRightOnEmptyLineStaysPut() {
        let buffer = FakeBuffer(
            lines: [
                "",
                "NEXT"
            ],
            cursor: Position(line: 0, column: 0)
        )
        
        let vim = VimEngine(buffer: buffer)
        vim.handleVimEvent(Util.makeKeyEvent("l"))
        vim.handleVimEvent(Util.makeKeyEvent("l"))
        
        #expect(buffer.cursorPosition() == Position(line: 0, column: 0))
    }
    
    @Test
    func movesRightStopsAtLastChar() {
        let line = "TESTING"
        let lastValid = line.count - 1
        
        let buffer = FakeBuffer(
            lines: [line],
            cursor: Position(line: 0, column: lastValid)
        )
        
        let vim = VimEngine(buffer: buffer)
        vim.handleVimEvent(Util.makeKeyEvent("l"))
        vim.handleVimEvent(Util.makeKeyEvent("l"))
        
        #expect(buffer.cursorPosition() == Position(line: 0, column: lastValid))
    }
}
