//
//  NM_ViewApp.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/17/26.
//

import SwiftData
import SwiftUI

@main
struct NM_ViewApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .modelContainer(for: [Workspace.self])
    }
}
