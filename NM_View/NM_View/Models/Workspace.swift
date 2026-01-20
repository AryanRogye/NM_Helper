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
    
    var searchTerms: [SearchTerm] = []
    
    public func doesSearchTermExist(_ term: String) -> Bool {
        for searchTerm in searchTerms {
            if searchTerm.term == term {
                return true
            }
        }
        
        return false
    }
    
    public func addSearchTerm(_ term: String) {
        searchTerms.append(.init(term))
    }
    
    init(
        file: URL
    ) {
        self.name = "\(file.lastPathComponent)-\(Date.now)"
        self.file = file
    }
}


@Model
final class SearchTerm {
    var dateCreated: Date
    var term: String
    
    init(_ term: String) {
        self.dateCreated = .now
        self.term = term
    }
}
