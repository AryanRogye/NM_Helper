//
//  DeleteUnderCursor.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import Testing
@testable import TextEditor

extension TextEditorTests {
    
    // 1. Basic: delete char under cursor in normal mode
    @Test
    func deleteDeletesCharUnderCursorInNormalMode() {
        let buffer = FakeBuffer(
            lines: [
                "ABC"
            ],
            cursor: Position(line: 0, column: 1) // on "B"
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        // Trigger delete (Self.delete)
        vimEngine.handleVimEvent(Util.makeKeyEvent("x"))
        
        let line = buffer.line(at: 0)
        let cursor = buffer.cursorPosition()
        
        #expect(line == "AC")
        // Cursor should stay at same column index, now pointing at "C"
        #expect(cursor.line == 0)
        #expect(cursor.column == 1)
        #expect(line.char(at: cursor.column) == "C")
    }
    
    // 2. Delete at end-of-file: should be a no-op
    @Test
    func deleteDoesNothingAtEndOfFile() {
        let text = "ABC"
        let buffer = FakeBuffer(
            lines: [text],
            cursor: Position(line: 0, column: text.count) // past last char
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.handleVimEvent(Util.makeKeyEvent("x"))
        
        let line = buffer.line(at: 0)
        let cursor = buffer.cursorPosition()
        
        #expect(line == text)               // no change
        #expect(cursor.line == 0)
        #expect(cursor.column == text.count - 1) // still at EOF
    }
    
    // 3. Visual mode: delete should delete selection range
    @Test
    func deleteDeletesSelectionInVisualMode() {
        let buffer = FakeBuffer(
            lines: [
                "HELLO WORLD"
            ],
            cursor: Position(line: 0, column: 0) // start at "H"
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .visual
        
        // Set visual anchor at current cursor
        vimEngine.visualAnchorLocation = buffer.cursorOffset()
        
        // Move cursor to select "HELLO"
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        vimEngine.handleVimEvent(Util.makeKeyEvent("l"))
        
        // Now delete selection
        vimEngine.handleVimEvent(Util.makeKeyEvent("x"))
        
        let line = buffer.line(at: 0)
        let cursor = buffer.cursorPosition()
        
        // "HELLO " removed, only "WORLD" left
        #expect(line == " WORLD" || line == "WORLD") // depends if your delete also removed the space
        #expect(cursor.line == 0)
        // cursor should be at start of remaining text
        #expect(cursor.column == 0)
        // state should be back to normal
        #expect(vimEngine.state == .normal)
    }
    
    // 4. Delete should not fire in insert mode (guard state != .insert)
    @Test
    func deleteDoesNothingInInsertMode() {
        let buffer = FakeBuffer(
            lines: [
                "DELETE ME"
            ],
            cursor: Position(line: 0, column: 0)
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .insert
        
        vimEngine.handleVimEvent(Util.makeKeyEvent("x"))
        
        let line = buffer.line(at: 0)
        let cursor = buffer.cursorPosition()
        
        // No change because state == .insert
        #expect(line == "DELETE ME")
        #expect(cursor.line == 0)
        #expect(cursor.column == 0)
        #expect(vimEngine.state == .insert)
    }
    
    // 5. Deleting a newline (cursor positioned on newline) should join lines
    @Test
    func deleteOnNewlineJoinsLines() {
        let buffer = FakeBuffer(
            lines: [
                "HELLO",
                "WORLD"
            ],
            cursor: Position(line: 0, column: "HELLO".count) // on newline between lines
        )
        
        let vimEngine = VimEngine(buffer: buffer)
        vimEngine.state = .normal
        
        vimEngine.handleVimEvent(Util.makeKeyEvent("x"))
        
        let line0 = buffer.line(at: 0)
        
        // Expect join: "HELLOWORLD" or "HELLO WORLD" depending on how FakeBuffer models newlines
        #expect(line0 == "HELLOWORLD" || line0 == "HELLO WORLD")
        
        let cursor = buffer.cursorPosition()
        #expect(cursor.line == 0)
        #expect(cursor.column == "HELLO".count) // stays at join point
    }
}
