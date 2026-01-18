//
//  VimCommands.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/7/25.
//

import LocalShortcuts

extension VimEngine {
    
    /// ESC Key
    static let escape = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.escape]
    )
    /// Control C
    static let normal_mode = LocalShortcuts.Shortcut(
        modifier: [.control],
        keys: [.c]
    )
    /// i
    static let insert_mode = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.i]
    )
    /// v
    static let visual_mode = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.v]
    )
    /// V or "shift v"
    static let visual_line_mode = LocalShortcuts.Shortcut(
        modifier: [.shift],
        keys: [.V]
    )
    /// : or "shift ;"
    static let command_mode = LocalShortcuts.Shortcut(
        modifier: [.shift],
        keys: [.semi_colon]
    )
    
    /// h
    static let move_left_one = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.h]
    )
    
    /// l
    static let move_right_one = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.l]
    )
    
    /// j
    static let move_down_one = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.j]
    )
    
    /// j
    static let move_up_one = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.k]
    )
    
    /// w
    static let move_word_next_leading = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.w]
    )
    
    /// e
    static let move_word_next_trailing = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.e]
    )
    
    /// b
    static let move_word_back = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.b]
    )
    
    /// A or "shift a"
    static let move_end_line_insert = LocalShortcuts.Shortcut(
        modifier: [.shift],
        keys: [.A]
    )
    
    /// $ or "shift 4"
    static let move_end_of_line = LocalShortcuts.Shortcut(
        modifier: [.shift],
        keys: [.dollar]
    )
    
    /// _ or "shift -"
    static let move_start_of_line = LocalShortcuts.Shortcut(
        modifier: [.shift],
        keys: [.underscore]
    )
    
    /// G or "shift g"
    static let bottom_of_file = LocalShortcuts.Shortcut(
        modifier: [.shift],
        keys: [.G]
    )
    
    
    /// g Modifier (meaning a `g`) was pressed
    static let g_modifier = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.g]
    )
    
    /// gg
    static let top_of_file = [
        g_modifier,
        g_modifier
    ]
    
    /// x
    static let delete = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.x]
    )
    static let deleteBeforeCursor = LocalShortcuts.Shortcut(
        modifier: [.shift],
        keys: [.X]
    )
    
    /// p
    static let paste = LocalShortcuts.Shortcut(
        modifier: [],
        keys: [.p]
    )
}
