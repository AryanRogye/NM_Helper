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
        .commands {
            SidebarCommands()
        }
    }
}

private struct SidebarCommands: Commands {
    @FocusedValue(\.sidebarToggleAction) private var sidebarToggleAction
    @FocusedValue(\.vimModeBinding) private var vimModeBinding
    @FocusedValue(\.sidebarStyleBinding) private var sidebarStyleBinding

    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button("Toggle Sidebar") {
                sidebarToggleAction?.toggle()
            }
            .disabled(sidebarToggleAction == nil)
        }

        CommandGroup(after: .textEditing) {
            if let vimModeBinding {
                Toggle("Vim Mode", isOn: vimModeBinding)
            } else {
                Button("Vim Mode") {}
                    .disabled(true)
            }
            
            if let sidebarStyleBinding {
                Toggle(
                    "Use NavigationSplitView",
                    isOn: Binding(
                        get: { sidebarStyleBinding.wrappedValue == .navigationSplit },
                        set: { sidebarStyleBinding.wrappedValue = $0 ? .navigationSplit : .custom }
                    )
                )
            }
        }
    }
}
