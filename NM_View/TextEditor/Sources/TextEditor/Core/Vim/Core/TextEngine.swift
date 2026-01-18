//
//  TextEngine.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/8/25.
//

struct TextEngine {
    internal static func calcLastWordDistanceLeading(states: [ClassifierChar], idx: Int) -> Int? {
        if states.isEmpty { return nil }
        
        var i = idx - 1
        
        /// 1. Skip Whitespace/Newlines backwards
        /// If we are at the start of a word (or on whitespace), this takes us to the end of the previous word.
        while i >= 0 {
            if states[i] == .space || states[i] == .newline {
                i -= 1
            } else {
                break
            }
        }
        
        /// If we hit start of file, we are done
        if i < 0 {
            return idx
        }
        
        /// 2. Consume the Word/Symbol backwards
        /// We are now on the last character of the previous word (or current word if we were in the middle).
        /// We scan back until the type changes.
        let targetType = states[i]
        while i >= 0 {
            if states[i] == targetType {
                i -= 1
            } else {
                break
            }
        }
        
        /// i is now at the character *before* the word start (or -1)
        /// Word start is i + 1
        /// Distance to move = idx - (i + 1)
        return idx - (i + 1)
    }
    
    
    internal static func calcNextWordLeadingDistance(states: [ClassifierChar], idx: Int) -> Int? {
        /// if empty no word next so return
        guard !states.isEmpty,
              idx >= 0,
              idx < states.count else {
            return nil
        }
        var count = 0
        let startType = states[idx]
        
        /// Phase 1: Consume the "current word"
        /// We keep going as long as the type matches what we started with.
        /// - If we started on a Word, we consume Words.
        /// - If we started on a Symbol, we consume Symbols (this handles // naturally).
        /// - If we started on Space, we skip this phase (count stays 0).
        if startType != .space && startType != .newline {
            while idx + count < states.count {
                let index = idx + count
                let currentType = states[index]
                
                /// Stop if we hit a different type (e.g. Word -> Symbol, or Symbol -> Space)
                if currentType != startType {
                    break
                }
                count += 1
            }
        }
        
        /// Phase 2: Consume Whitespace
        /// Now that we've finished the current "block", we skip any whitespace after it.
        while idx + count < states.count {
            let index = idx + count
            if states[index] == .space {
                count += 1
            } else {
                /// Found the start of the next word (or newline)!
                break
            }
        }
        
        return count
    }

    internal static func calcNextWordTrailingDistance(states: [ClassifierChar], idx: Int) -> Int? {
        /// Ensure we are not already at the very end
        guard !states.isEmpty,
              idx >= 0,
              idx < states.count - 1 else {
            return nil
        }
        
        var count = 1 // 'e' always moves at least 1 character forward
        
        /// Phase 1: Skip Whitespace
        /// If we are on whitespace (or moved onto it), keep going until we hit a Word, Symbol, or Newline
        while idx + count < states.count {
            if states[idx + count] == .space {
                count += 1
            } else {
                break
            }
        }
        
        /// Check bounds after skipping space
        if idx + count >= states.count {
            return count - 1
        }
        
        /// Phase 2: Find the End of the current block
        /// We are now on the first character of the target word/symbol.
        /// We advance as long as the *next* character matches this type.
        let targetType = states[idx + count]
        
        // Treat newline as a single-char block (optional, depends on your newline preference)
        if targetType == .newline {
            return count
        }
        
        while idx + count + 1 < states.count {
            let nextType = states[idx + count + 1]
            
            if nextType == targetType {
                count += 1
            } else {
                break
            }
        }
        
        return count
    }

    
}
