//
//  HomeView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/17/26.
//

import SwiftUI
import SwiftData
import TextEditor

struct HomeView: View {
    
    @Environment(\.modelContext) var ctx
    @State private var vm: NMViewModel
    @State private var isSidebarVisible: Bool = true
    
    init() {
        vm = .init()
    }
    
    var body: some View {
        SidebarLayout(isSidebarVisible: isSidebarVisible, minSidebarWidth: 240) {
            Sidebar(vm: vm)
        } content: {
            VStack {
                switch vm.currentScreen {
                case .home:
                    if let w = vm.selectedWorkspace {
                        WorkspaceView(vm: vm, workspace: w)
                    }
                case .addView:
                    AddView(vm: vm)
                }
            }
            .task { vm.bind(to: ctx) }
            // MARK: - TOOLBAR
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSidebarVisible.toggle()
                        }
                    } label: {
                        Image(systemName: isSidebarVisible ? "sidebar.leading" : "sidebar.trailing")
                    }
                    .help(isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")
                    .keyboardShortcut("s", modifiers: [.command, .option])
                }
//                if let size = vm.size {
//                    ToolbarItem(placement: .automatic) {
//                        Text("Size: \(Int(size))")
//                            .monospacedDigit()
//                            .padding(.vertical, 8)
//                    }
//                }
            }
            .background(
                WindowAccessor { window in
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    window.isMovableByWindowBackground = true
                }
            )
        }
    }
}
