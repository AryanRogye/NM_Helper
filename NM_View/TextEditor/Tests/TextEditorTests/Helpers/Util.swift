//
//  Util.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/9/25.
//

import AppKit

struct Util {
    static func makeKeyEvent(_ char: String) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: char,
            charactersIgnoringModifiers: char,
            isARepeat: false,
            keyCode: 0
        )!
    }
}
