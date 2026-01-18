//
//  VimState.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/5/25.
//

enum VimState {
    case command
    case normal
    case insert
    case visual
    case visualLine
}

extension VimState {
    var displayName: String {
        switch self {
        case .command:
            return "Command"
        case .normal:
            return "Vim"
        case .insert:
            return "Insert"
        case .visual, .visualLine:
            return "Visual"
        }
    }
}
