//
//  VimMovement.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/7/25.
//

@MainActor
extension VimEngine {
    internal func handleLastWordLeading() {
        let visualAnchorPos = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos = motionEngine.lastWordLeading(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func handleNextWordLeading() {
        let visualAnchorPos = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos = motionEngine.nextWordLeading(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func handleNextWordTrailing() {
        let visualAnchorPos = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos = motionEngine.nextWordTrailing(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func moveLeft() {
        let visualAnchorPos: Position? = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos: Position = motionEngine.leftOne(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func moveRight() {
        let visualAnchorPos: Position? = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos: Position = motionEngine.rightOne(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func moveUp() {
        let visualAnchorPos: Position? = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos: Position = motionEngine.up(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func moveDown() {
        let visualAnchorPos: Position? = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos: Position = motionEngine.down(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func moveToEndOfLine() {
        let visualAnchorPos: Position? = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos: Position = motionEngine.moveToEndOfLine(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func moveToStartOfLine() {
        let visualAnchorPos: Position? = buffer.currentVisualHead(anchor: visualAnchorLocation)
        let pos: Position = motionEngine.moveToStartOfLine(visualAnchorPos)
        buffer.moveTo(position: pos)
    }
    internal func deleteUnderCursor() {
        buffer.deleteUnderCursor()
    }
    internal func deleteBeforeCursor() {
        buffer.deleteBeforeCursor()
    }
    internal func moveToBottomOfFile() {
        buffer.moveToBottomOfFile()
    }
    internal func moveToTopOfFile() {
        buffer.moveToTopOfFile()
    }
    internal func moveDownAndStartOfLine() {
        buffer.moveDownAndStartOfLine()
    }
    
    internal func pasteAtCursorOrSelection() {
        buffer.paste()
    }
}
