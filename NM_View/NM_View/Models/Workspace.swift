//
//  Workspace.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/17/26.
//

import SwiftData
import Foundation

@Model
final class Workspace: Sendable {
    
    var name: String
    var file: URL
    
    @Transient
    var size: Int? = nil
    
    init(
        file: URL
    ) {
        self.name = "\(file.lastPathComponent)-\(Date.now)"
        self.file = file
    }
}
