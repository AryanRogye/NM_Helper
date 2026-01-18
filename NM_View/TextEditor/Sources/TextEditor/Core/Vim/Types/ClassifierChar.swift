//
//  ClassifierChar.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/7/25.
//

public enum ClassifierChar {
    case word
    case space
    case newline
    case symbol
    
    public func smallLabel() -> String {
        switch self {
        case .word: return "[WORD]"
        case .space: return "[SPACE]"
        case .newline: return "[NEWLINE]"
        case .symbol: return "[SYMBOL]"
        }
    }
    
    /// Defining word characters by definition
    static let wordCharacters: Set<Character> = [
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q",
        "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q",
        "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "_",
    ]
    
    public static func line(_ line: String) -> [ClassifierChar] {
        var list : [ClassifierChar] = []
        for c in line {
            list.append(.init(from: c))
        }
        return list
    }
    
    public init(from c: Character) {
        if c == "\n" {
            self = .newline
        } else if c.isWhitespace {
            self = .space
        } else if Self.wordCharacters.contains(c) {
            self = .word
        } else {
            self = .symbol
        }
    }
}
