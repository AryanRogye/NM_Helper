//
//  NextWordTrailing.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import Testing
@testable import TextEditor

extension TextEditorTests {
    @Test
    func nextWordTrailingInVisualModeExpandsSelection() {
        let buffer = FakeBuffer(
            lines: ["one two"],
            cursor: Position(line: 0, column: 0) // 'o'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .visual
        vim.visualAnchorLocation = buffer.cursorOffset()
        
        vim.handleVimEvent(Util.makeKeyEvent("e"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 2)) // 'e'
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 0)
        #expect(selection?.length == 3)
    }
    
    @Test
    func nextWordTrailingMovesToEndOfCurrentWord() {
        let buffer = FakeBuffer(
            lines: ["one two"],
            cursor: Position(line: 0, column: 0) // 'o'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("e"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 2)) // 'e'
    }
    
    @Test
    func nextWordTrailingFromInsideWord_goesToEnd() {
        let buffer = FakeBuffer(
            lines: ["one two"],
            cursor: Position(line: 0, column: 1) // 'n'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("e"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 2)) // 'e'
    }
    
    @Test
    func nextWordTrailingCrossesToEndOfNextWord() {
        let buffer = FakeBuffer(
            lines: ["one two"],
            cursor: Position(line: 0, column: 3) // space after "one"
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("e"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 6)) // 'o' in "two"
    }
    
    @Test
    func nextWordTrailingStaysAtEndOfLastWord() {
        let line = "one two"
        let buffer = FakeBuffer(
            lines: [line],
            cursor: Position(line: 0, column: line.count - 1)
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("e"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: line.count - 1))
    }
}
