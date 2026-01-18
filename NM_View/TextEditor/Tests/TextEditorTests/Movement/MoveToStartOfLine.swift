//
//  MoveToStartOfLine.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import Testing
@testable import TextEditor

extension TextEditorTests {
    @Test
    func moveToStartOfLineUpdatesSelectionInVisualMode() {
        let buffer = FakeBuffer(
            lines: ["TESTING"],
            cursor: Position(line: 0, column: 3)
        )
        
        let vim = VimEngine(buffer: buffer)
        vim.state = .visual
        vim.visualAnchorLocation = buffer.cursorOffset()
        
        vim.moveToStartOfLine()
        // Manually mirror visual selection update since we call the movement directly
        buffer.updateCursorAndSelection(anchor: vim.visualAnchorLocation, to: buffer.cursorOffset())
        
        let pos = buffer.cursorPosition()
        #expect(pos.line == 0)
        #expect(pos.column == 0)
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 0)
        #expect(selection?.length == 4)
    }
    
    @Test
    func moveToStartOfLine_basic() {
        let buffer = FakeBuffer(
            lines: ["TESTING"],
            cursor: Position(line: 0, column: 4)
        )
        
        let vim = VimEngine(buffer: buffer)
        vim.moveToStartOfLine()
        
        let pos = buffer.cursorPosition()
        #expect(pos.line == 0)
        #expect(pos.column == 0)
    }
    
    @Test
    func moveToStartOfLine_onEmptyLine_staysZero() {
        let buffer = FakeBuffer(
            lines: [""],
            cursor: Position(line: 0, column: 0)
        )
        
        let vim = VimEngine(buffer: buffer)
        vim.moveToStartOfLine()
        
        let pos = buffer.cursorPosition()
        #expect(pos.line == 0)
        #expect(pos.column == 0)
    }
    
    @Test
    func moveToStartOfLine_onSecondLine() {
        let buffer = FakeBuffer(
            lines: ["FIRST", "SECOND"],
            cursor: Position(line: 1, column: 3)
        )
        
        let vim = VimEngine(buffer: buffer)
        vim.moveToStartOfLine()
        
        let pos = buffer.cursorPosition()
        #expect(pos.line == 1)
        #expect(pos.column == 0)
    }
}
