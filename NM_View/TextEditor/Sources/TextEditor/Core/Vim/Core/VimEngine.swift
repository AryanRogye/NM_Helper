//
//  VimEngine.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/5/25.
//

import AppKit
import LocalShortcuts

@MainActor
class VimEngine: ObservableObject {

    /// if we are in vim or not
    @Published var isInVimMode = false
    /// What the state of vim mode we are in
    @Published var state : VimState = .normal

    @Published var position : Position?
    @Published var isOnNewLine: Bool = false
    
    @Published var commandBuffer: String = ":"

    var lastShortcut: LocalShortcuts.Shortcut?

    public var buffer : BufferView

    internal lazy var motionEngine = MotionEngine(buffer: buffer)

    @Published var visualAnchorLocation: Int?
    
    var onSave: (() -> Void)? = nil
    var onSearchRequested: (() -> Void)? = nil

    public func updatePosition() {
        let p = buffer.cursorPosition()
        DispatchQueue.main.async {
            self.position = p
        }
        if let c = buffer.char(at: p) {
            isOnNewLine = c == "\n"
        }
    }

    init(buffer: BufferView = NSTextViewBufferAdapter()) {
        self.buffer = buffer
    }


    @discardableResult
    public func handleVimEvent(_ event: NSEvent) -> Bool {
        /// if not set just keep typing

        /// we can get the key from the event
        let shortcut: LocalShortcuts.Shortcut = LocalShortcuts.Shortcut.getShortcut(event: event)

        /// Shortcut holds all modifiers and keys
        /// First Check if is control c

        var didJustInsert: Bool = false
        var didJustCommand: Bool = false
        var didPressInsertButIsInsertMode: Bool = false
        var didPressCommandButIsCommandMode: Bool = false
        var didJustMoveToEndOfLine: Bool = false

        if state != .insert,
           state != .command,
           let chars = event.characters,
           chars == "/" {
            onSearchRequested?()
            return false
        }

        switch shortcut {
            
            // MARK: - Escape
        case Self.escape:
            /// In insert mode if "escape" switches to normal mode
            if state == .insert  { enterNormalMode() }
            /// In command mode if "escape" switches to normal mode
            else if state == .command { enterNormalMode() }
            
            /// In visual mode if "escape" exit visual + enter normal
            else if state == .visual {
                exitVisualMode()
                enterNormalMode()
            }
            /// In visual line mode if "escape" exit visual line + enter normal
            else if state == .visualLine {
                exitVisualLineMode()
                enterNormalMode()
            }
            /// ================================================================================================
            // MARK: - Command-Mode
        case Self.command_mode:
            /// Just Return on this
            if state == .command {
                didPressCommandButIsCommandMode = true
                break
            }
            /// Insert is the only case in which it should break on
            if state == .insert { break }
            /// else we enter command mode
            enterCommandMode()
            didJustCommand = true
            
            // MARK: - Normal Mode
        case Self.normal_mode:
            /// If Visual Exit
            if state == .visual { exitVisualMode() }
            /// If Visual Line Exit
            else if state == .visualLine { exitVisualLineMode() }
            
            /// Enter Normal Mode
            enterNormalMode()
            
            // MARK: - Insert Mode
        case Self.insert_mode:
            /// if we're in command mode, dont do anything
            if state == .command ||
                /// if we're in visual break dont do anything
                state == .visual ||
                /// If we're in visual line dont do anything
                state == .visualLine { break }
            /// if we press insert, but we're already in insert, just break out as well but
            /// mark it
            else if state == .insert {
                didPressInsertButIsInsertMode = true
                break
            }
            /// Set Insert
            state = .insert
            didJustInsert = true
            
            // MARK: - Visual Mode
        case Self.visual_mode:
            /// If we're in insert, dont do anything
            if state == .insert ||
                /// if we're in command, dont do anything
                state == .command { break }
            
            /// Enter Visual Mode
            enterVisualMode()
            
            // MARK: - Visual Line Mode
        case Self.visual_line_mode:
            /// If we're in insert, dont do anything
            if state == .insert ||
                /// if we're in command, dont do anything
                state == .command { break }
            
            /// Enter Visual Line Mode
            enterVisualLineMode()
            /// ================================================================================================
            
            
            // MARK: - Deletion on Word
        case Self.delete:
            /// If we're in insert, dont do anything
            if state == .insert ||
                /// if we're in command, dont do anything
                state == .command { break }
            /// Normal Delete is just delete char underneath
            deleteUnderCursor()
            
            /// Enter Normal Mode
            enterNormalMode()
        case Self.deleteBeforeCursor:
            /// If we're in insert, dont do anything
            if state == .insert ||
                /// if we're in command, dont do anything
                state == .command { break }
            
            if state == .visual || state == .visualLine {
                deleteUnderCursor()
            } else {
                deleteBeforeCursor()
            }
            
            enterNormalMode()

            // MARK: -
        case Self.paste:
            /// If we're in insert, dont do anything
            if state == .insert ||
                /// If we're in insert, dont do anything
                state == .command { break}
            
            /// Paste at Content
            pasteAtCursorOrSelection()
            
            /// No Matter What at the end we flip to a Normal Mode
            enterNormalMode()
            
            
            // MARK: - MOVEMENT
        case Self.move_left_one:
            if state == .command  { break }
            if state != .insert {
                moveLeft()
            }
        case Self.move_right_one:
            if state == .command  { break }
            if state != .insert {
                moveRight()
            }
        case Self.move_up_one:
            if state == .command  { break }
            if state != .insert {
                moveUp()
            }
        case Self.move_down_one:
            if state == .command  { break }
            if state != .insert {
                moveDown()
            }

        case Self.move_word_next_leading:
            if state == .command  { break }
            if state != .insert {
                handleNextWordLeading()
            }
        case Self.move_word_next_trailing:
            if state == .command  { break }
            if state != .insert {
                handleNextWordTrailing()
            }
        case Self.move_word_back:
            if state == .command  { break }
            if state != .insert {
                handleLastWordLeading()
            }

        case Self.move_end_line_insert:
            if state == .command  { break }
            if state != .insert {
                didJustMoveToEndOfLine = true
                moveToEndOfLine()
                state = .insert
            }
        case Self.move_end_of_line:
            if state == .command  { break }
            if state != .insert {
                moveToEndOfLine()
            }
        case Self.move_start_of_line:
            if state == .command  { break }
            if state != .insert {
                moveToStartOfLine()
            }
        case Self.bottom_of_file:
            if state == .command  { break }
            if state != .insert {
                moveToBottomOfFile()
            }
        case Self.g_modifier:
            if state == .command  { break }
            if state != .insert {
                if let lastShortcut = lastShortcut {
                    let top_of_file_pattern: [LocalShortcuts.Shortcut] = [
                        lastShortcut,
                        Self.g_modifier,
                    ]
                    if top_of_file_pattern == Self.top_of_file {
                        moveToTopOfFile()
                    }
                }
            }
        default: break
        }

        lastShortcut = shortcut

        /// Update's the insertion point
        buffer.updateInsertionPoint()

        /// If In Visual Mode
        if state == .visual {
            if let range = buffer.getCursorPosition() {
                buffer.updateCursorAndSelection(anchor: visualAnchorLocation, to: range.location)
            }
        }
        if state == .visualLine {
            if let range = buffer.getCursorPosition() {
                buffer.updateCursorAndSelectLine(anchor: visualAnchorLocation, to: range.location)
            }
        }
        if state == .command && !didJustCommand {
            if let c = event.characters {
                debugPrint("C: \(c)")
                if c == "\n" || c == "\r" {
                    evaluateCommandBuffer()
                    enterNormalMode()
                }
                else if c == "\u{7F}" {
                    if commandBuffer.count > 1 {
                        let sub = commandBuffer.dropLast(1)
                        commandBuffer = sub.description
                    }
                }
                else {
                    commandBuffer += c
                }
            }
        }

        /// Returning True allows us to type in what we just did
        if didPressInsertButIsInsertMode || didPressCommandButIsCommandMode {
            return true
        }

        if didJustCommand || didJustInsert || didJustMoveToEndOfLine {
            return false
        }
        

        return state == .insert
    }
    
    private func evaluateCommandBuffer() {
        switch commandBuffer {
        case ":w": onSave?()
        default: break
        }
        
        commandBuffer = ":"
    }
    
    private func clearCommandBuffer() {
        commandBuffer = ":"
    }

    private func enterCommandMode() {
        clearCommandBuffer()
        state = .command
    }
    private func exitCommandMode() {
        enterNormalMode()
    }
    private func enterNormalMode() {
        state = .normal
        let currentPos = buffer.cursorPosition()
        let c = buffer.line(at: currentPos.line).char(at: currentPos.column)
        if c == nil || c == "\n" {
            moveLeft()
        }
    }
    private func enterVisualMode() {
        visualAnchorLocation = buffer.cursorOffset()
        state = .visual
    }
    private func enterVisualLineMode() {
        visualAnchorLocation = buffer.cursorOffset()
        state = .visualLine
    }
    private func exitVisualMode() {
        buffer.exitVisualMode()
    }
    private func exitVisualLineMode() {
        buffer.exitVisualMode()
    }
}
