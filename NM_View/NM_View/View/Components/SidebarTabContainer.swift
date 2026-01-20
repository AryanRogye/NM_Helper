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
                .frame(maxHeight: .infinity)

            if let currentIndex = vm.currentIndex {
                Divider()
                SidebarCurrentIndexPanel(
                    index: currentIndex,
                    symbol: currentSymbol
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
    }

    private var currentSymbol: Symbols? {
        guard let currentIndex = vm.currentIndex else { return nil }
        return vm.selectedWorkspaceSymbols[currentIndex]
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

private struct SidebarCurrentIndexPanel: View {
    let index: Int
    let symbol: Symbols?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            currentIndexBarContent
            Divider()
            debugSlotView
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var currentIndexBarContent: some View {
        HStack(spacing: 8) {
            CurrentIndexChip(title: "Index", value: "#\(index)", accent: .primary)
            if let symbol {
                CurrentIndexChip(
                    title: "Symbol",
                    value: symbol.symbolType.rawValue.trimmingCharacters(in: .whitespaces),
                    accent: .accentColor
                )
                Text(symbol.symbolType.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                CurrentIndexChip(title: "Symbol", value: "—", accent: .secondary)
                Text("No symbol at this index")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var debugSlotView: some View {
        HStack {
            Text("Debug slot")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct CurrentIndexChip: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial, in: Capsule())
    }
}
