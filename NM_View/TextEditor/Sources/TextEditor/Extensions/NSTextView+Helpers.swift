//
//  ComfyTextView+Helpers.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/7/25.
//

import AppKit

extension NSTextView {
    /// Move right by a certain amount
    public func moveRight(count: Int = 1) {
        for _ in 0..<count {
            moveRight(self)
        }
    }
    public func moveLeft(count: Int = 1) {
        for _ in 0..<count {
            moveLeft(self)
        }
    }
}
