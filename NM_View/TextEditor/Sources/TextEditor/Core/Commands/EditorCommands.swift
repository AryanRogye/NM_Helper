//
//  EditorCommands.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/24/25.
//


@MainActor
public protocol EditorCommands: AnyObject {
    func toggleBold()
    func increaseFontOrZoomIn()
    func decreaseFontOrZoomOut()
}
