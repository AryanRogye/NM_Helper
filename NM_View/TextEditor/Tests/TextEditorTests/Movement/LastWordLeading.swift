//
//  LastWordLeading.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import Testing
@testable import TextEditor

extension TextEditorTests {
    @Test
    func lastWordLeadingInVisualModeExpandsSelectionBackward() {
        let buffer = FakeBuffer(
            lines: ["one two"],
            cursor: Position(line: 0, column: 5) // 'w'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .visual
        vim.visualAnchorLocation = buffer.cursorOffset()
        
        vim.handleVimEvent(Util.makeKeyEvent("b"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 4)) // 't'
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 4)
        #expect(selection?.length == 2)
    }
    
    @Test
    func lastWordLeadingMovesToStartOfCurrentWord() {
        let buffer = FakeBuffer(
            lines: ["one two"],
            cursor: Position(line: 0, column: 5) // 'w'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("b"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 4)) // 't'
    }
    
    @Test
    func lastWordLeadingFromStartOfWord_goesToPrevWord() {
        let buffer = FakeBuffer(
            lines: ["one two"],
            cursor: Position(line: 0, column: 4) // 't'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("b"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 0)) // 'o'
    }
    
    @Test
    func lastWordLeadingStaysAtStartOfFile() {
        let buffer = FakeBuffer(
            lines: ["one"],
            cursor: Position(line: 0, column: 0)
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("b"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 0))
    }
    
    @Test
    func lastWordLeadingCrossesLineUp() {
        let buffer = FakeBuffer(
            lines: [
                "one",
                "two"
            ],
            cursor: Position(line: 1, column: 0) // 't'
        )
        let vim = VimEngine(buffer: buffer); vim.state = .normal
        
        vim.handleVimEvent(Util.makeKeyEvent("b"))
        #expect(buffer.cursorPosition() == Position(line: 0, column: 0)) // 'o'
    }
}
