//
//  NextWordLeading.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import Testing
@testable import TextEditor

extension TextEditorTests {
    @Test
    func nextWordLeadingInVisualModeExpandsSelection() {
        let buffer = FakeBuffer(
            lines: ["one two three"],
            cursor: Position(line: 0, column: 0) // at 'o'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .visual
        vim.visualAnchorLocation = buffer.cursorOffset()
        
        vim.handleVimEvent(Util.makeKeyEvent("w"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 4)) // 't' in "two"
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 0)
        #expect(selection?.length == 5)
    }
    
    @Test
    func nextWordLeadingMovesToStartOfNextWord() {
        let buffer = FakeBuffer(
            lines: ["one two three"],
            cursor: Position(line: 0, column: 0) // at 'o'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("w"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 4)) // 't' in "two"
    }
    
    @Test
    func nextWordLeadingFrom_middleOfWord_goesToNextWord() {
        let buffer = FakeBuffer(
            lines: ["one two"],
            cursor: Position(line: 0, column: 1) // 'n' in "one"
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("w"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 4)) // 't'
    }
    
    @Test
    func nextWordLeadingSkips_multipleSpaces() {
        let buffer = FakeBuffer(
            lines: ["one   two"],
            cursor: Position(line: 0, column: 0)
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("w"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 6)) // still 't'
    }
    
    @Test
    func nextWordLeadingCrossesLine_whenAtEnd() {
        let buffer = FakeBuffer(
            lines: [
                "one",
                "two"
            ],
            cursor: Position(line: 0, column: 3) // after "one"
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("w"))
        #expect(buffer.cursorPosition() == Position(line: 1, column: 0)) // 't'
    }
    
    @Test
    func nextWordLeadingAtLastWord_staysAtEnd() {
        let line = "one"
        let buffer = FakeBuffer(
            lines: [line],
            cursor: Position(line: 0, column: line.count - 1)
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("w"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: line.count - 1))
    }
}
