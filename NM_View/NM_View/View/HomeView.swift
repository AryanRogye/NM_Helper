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
        layoutView
            .background(sidebarShortcutHandler)
            .focusedSceneValue(\.sidebarToggleAction, SidebarToggleAction {
                vm.toggleSidebar()
            })
            .focusedSceneValue(\.vimModeBinding, $vm.isInVimMode)
    }
}

// MARK: - Layout
extension HomeView {
    @ViewBuilder
    private var layoutView: some View {
        NavigationSplitView(columnVisibility: splitVisibilityBinding) {
            SidebarTabContainer(vm: vm)
                .navigationSplitViewColumnWidth(min: 280, ideal: 400, max: 520)
        } detail: {
            mainContentView
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var mainContentView: some View {
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
        }
        .background(
            WindowAccessor { window in
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
            }
        )
    }

    private var splitVisibilityBinding: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { vm.isSidebarVisible ? .all : .detailOnly },
            set: { newValue in
                vm.isSidebarVisible = newValue != .detailOnly
            }
        )
    }
}

private extension HomeView {
    var sidebarShortcutHandler: some View {
        Button("") {
            vm.toggleSidebar()
        }
        .keyboardShortcut("s", modifiers: [.command])
        .buttonStyle(.plain)
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
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
