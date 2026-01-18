//
//  MoveToEndOfLine.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import Testing
@testable import TextEditor

extension TextEditorTests {
    @Test
    func moveToEndOfLineUpdatesSelectionInVisualMode() {
        let line = "TESTING"
        let buffer = FakeBuffer(
            lines: [
                line,
                line
            ],
            cursor: Position(line: 0, column: 1)
        )
        #expect(buffer.cursorPosition() == Position(line: 0, column: 1))
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .visual
        vimEngine.visualAnchorLocation = buffer.cursorOffset()
        
        vimEngine.moveToEndOfLine()
        // Apply the same selection update visual mode would perform after movement
        buffer.updateCursorAndSelection(anchor: vimEngine.visualAnchorLocation, to: buffer.cursorOffset())
        
        let newCursor = buffer.cursorPosition()
        #expect(newCursor.line == 0)
        #expect(newCursor.column == line.count)
        
        let selection = buffer.getCursorPosition()
        #expect(selection?.location == 1)
        #expect(selection?.length == line.count)
        
        let endChar = buffer.line(at: newCursor.line).char(at: newCursor.column)
        #expect(endChar == "\n")
    }
    
    @Test
    func moveToEndOfLine_basic() {
        let line = "TESTING"
        let buffer = FakeBuffer(
            lines: [
                line,
                line
                   ],
            cursor: Position(line: 0, column: 0)
        )
        #expect(buffer.cursorPosition() == Position(line: 0, column: 0))
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.moveToEndOfLine()
        
        let newCursor = buffer.cursorPosition()
        #expect(newCursor.line == 0)
        #expect(newCursor.column == line.count)
        
        let endChar = buffer.line(at: newCursor.line).char(at: newCursor.column)
        #expect(endChar == "\n")
    }
    
    @Test
    func moveToEndOfLine_fromMiddle() {
        let line = "TESTING"
        let buffer = FakeBuffer(
            lines: [
                line,
                line
            ],
            cursor: Position(line: 0, column: 2) // 'S'
        )
        #expect(buffer.cursorPosition() == Position(line: 0, column: 2))
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.moveToEndOfLine()
        
        let newCursor = buffer.cursorPosition()
        #expect(newCursor.line == 0)
        #expect(newCursor.column == line.count)
        
        let endChar = buffer.line(at: newCursor.line).char(at: newCursor.column)
        #expect(endChar == "\n")
    }
    
    @Test
    func moveToEndOfLine_onSecondLine() {
        let line1 = "FIRST"
        let line2 = "SECOND LINE"
        let buffer = FakeBuffer(
            lines: [
                line1,
                line2,
                line1
            ],
            cursor: Position(line: 1, column: 0) // start of second line
        )
        #expect(buffer.cursorPosition() == Position(line: 1, column: 0))
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.moveToEndOfLine()
        
        let newCursor = buffer.cursorPosition()
        #expect(newCursor.line == 1)
        #expect(newCursor.column == line2.count)
        
        let endChar = buffer.line(at: newCursor.line).char(at: newCursor.column)
        #expect(endChar == "\n")
    }
    
    @Test
    func moveToEndOfLine_onEmptyLine_staysAtZero() {
        let buffer = FakeBuffer(
            lines: [
                "",
                ""
            ],
            cursor: Position(line: 0, column: 0)
        )
        #expect(buffer.cursorPosition() == Position(line: 0, column: 0))
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.moveToEndOfLine()
        
        let newCursor = buffer.cursorPosition()
        #expect(newCursor.line == 0)
        #expect(newCursor.column == 0)
        
        let endChar = buffer.line(at: newCursor.line).char(at: newCursor.column)
        #expect(endChar == "\n")
    }
    
    @Test
    func moveToEndOfLine_whenAlreadyAtEnd_noChange() {
        let line = "TESTING"
        let buffer = FakeBuffer(
            lines: [
                line,
                line
            ],
            cursor: Position(line: 0, column: line.count - 1)
        )
        #expect(buffer.cursorPosition() == Position(line: 0, column: line.count - 1))
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.moveToEndOfLine()
        
        let newCursor = buffer.cursorPosition()
        #expect(newCursor.line == 0)
        #expect(newCursor.column == line.count)
        
        let endChar = buffer.line(at: newCursor.line).char(at: newCursor.column)
        #expect(endChar == "\n")
    }
}
