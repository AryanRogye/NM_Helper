//
//  Position.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/7/25.
//

import Foundation

public struct Position: Identifiable, Equatable {
    public let id = UUID()
    var line: Int
    var column: Int
    
    public static func == (lhs: Position, rhs: Position) -> Bool {
        lhs.line == rhs.line && lhs.column == rhs.column
    }
}
