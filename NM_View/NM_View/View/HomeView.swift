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
    
    init() {
        vm = .init()
    }
    
    var body: some View {
        SidebarLayout(isSidebarVisible: vm.isSidebarVisible, minSidebarWidth: 400) {
            SidebarTabContainer(vm: vm)
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
                        vm.toggleSidebar()
                    } label: {
                        Image(systemName: vm.isSidebarVisible ? "sidebar.leading" : "sidebar.trailing")
                    }
                    .help(vm.isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")
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
        .focusedSceneValue(\.sidebarToggleAction, SidebarToggleAction {
            vm.toggleSidebar()
        })
        .focusedSceneValue(\.vimModeBinding, $vm.isInVimMode)
    }
}

struct SidebarToggleAction {
    let toggle: () -> Void
}

struct SidebarToggleActionKey: FocusedValueKey {
    typealias Value = SidebarToggleAction
}

extension FocusedValues {
    var sidebarToggleAction: SidebarToggleAction? {
        get { self[SidebarToggleActionKey.self] }
        set { self[SidebarToggleActionKey.self] = newValue }
    }
}

struct VimModeBindingKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var vimModeBinding: Binding<Bool>? {
        get { self[VimModeBindingKey.self] }
        set { self[VimModeBindingKey.self] = newValue }
    }
}
