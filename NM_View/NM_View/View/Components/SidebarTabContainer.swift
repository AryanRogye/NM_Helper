//
//  SidebarTabContainer.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/18/26.
//

import SwiftUI

struct SidebarTabContainer: View {
    @Bindable var vm: NMViewModel

    var body: some View {
        VStack(spacing: 0) {
            SidebarTabHeader(selection: $vm.sidebarTab)

            Divider()

            SidebarTabContent(vm: vm)
        }
    }
}

// MARK: - Header
private struct SidebarTabHeader: View {
    @Binding var selection: SidebarTab

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(SidebarTab.allCases) { tab in
                Text(tab.title)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(12)
    }
}

// MARK: - Content
private struct SidebarTabContent: View {
    @Bindable var vm: NMViewModel

    var body: some View {
        Group {
            switch vm.sidebarTab {
            case .sidebar:
                SidebarWorkspaceTabView(vm: vm)
            case .panel:
                SidebarSearchPanelView(vm: vm)
            case .symbol_types:
                SidebarSymbolView(vm: vm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
