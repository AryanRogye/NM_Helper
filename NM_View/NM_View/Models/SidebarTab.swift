//
//  SidebarTab.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/19/26.
//

import Foundation

enum SidebarTab: String, CaseIterable, Identifiable {
    case sidebar
    case panel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sidebar:
            return "Sidebar"
        case .panel:
            return "Panel"
        }
    }
}
