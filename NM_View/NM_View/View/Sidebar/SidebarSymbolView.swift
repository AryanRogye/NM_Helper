//
//  SidebarSymbolView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/18/26.
//

import SwiftUI

struct SidebarSymbolView: View {
    
    @Bindable var vm: NMViewModel
    @State private var showIndices = true
    @State private var showEmptyTypes = false
    @State private var expandedTypes: Set<SymbolType> = []
    private let indexPreviewLimit = 120
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            contentView
        }
    }
}

// MARK: - Header
extension SidebarSymbolView {
    private var headerView: some View {
        HStack(spacing: 8) {
            Text("Symbols Debug")
                .font(.headline)
            Spacer()
            StatusPill(text: statusText, color: statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Content
extension SidebarSymbolView {
    private var contentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                summaryView
                if symbolGroups.isEmpty {
                    emptyStateView
                } else {
                    ForEach(symbolGroups) { group in
                        SymbolGroupView(
                            group: group,
                            isExpanded: bindingForGroup(group.type),
                            showIndices: showIndices,
                            limit: indexPreviewLimit,
                            onSelect: { index in
                                vm.goToHighlight(index)
                            }
                        )
                    }
                }
            }
            .padding(12)
        }
    }

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let workspace = vm.selectedWorkspace {
                Text(workspace.file.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            HStack(spacing: 8) {
                MetricChip(title: "Total", value: "\(vm.selectedWorkspaceSymbols.count)")
                MetricChip(title: "Types", value: "\(distinctTypeCount)")
                MetricChip(title: "Chunks", value: "\(vm.selectedChunks.count)")
            }
            HStack(spacing: 12) {
                Toggle("Show indices", isOn: $showIndices)
                    .toggleStyle(.checkbox)
                Toggle("Include empty types", isOn: $showEmptyTypes)
                    .toggleStyle(.checkbox)
            }
            .font(.caption)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text(emptyStateTitle)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(emptyStateSubtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Derived Data
extension SidebarSymbolView {
    private var statusText: String {
        if vm.isScanningSymbols || vm.isLoadingChunks || vm.isNMScanning {
            return "Scanning"
        }
        return vm.selectedWorkspaceSymbols.isEmpty ? "Empty" : "Ready"
    }

    private var statusColor: Color {
        if vm.isScanningSymbols || vm.isLoadingChunks || vm.isNMScanning {
            return .orange
        }
        return vm.selectedWorkspaceSymbols.isEmpty ? .gray : .green
    }

    private var distinctTypeCount: Int {
        Set(vm.selectedWorkspaceSymbols.map(\.symbolType)).count
    }

    private var emptyStateTitle: String {
        if vm.isNMScanning || vm.isLoadingChunks {
            return "Loading nm output…"
        }
        if vm.isScanningSymbols {
            return "Scanning symbols…"
        }
        return "No symbols yet"
    }

    private var emptyStateSubtitle: String {
        if vm.selectedWorkspace == nil {
            return "Select a workspace to populate symbols."
        }
        return "Run a scan to populate the sidebar."
    }

    private var symbolGroups: [SymbolGroup] {
        let grouped = Dictionary(grouping: vm.selectedWorkspaceSymbols, by: { $0.symbolType })
        return SymbolType.allCases.compactMap { type in
            let symbols = grouped[type] ?? []
            if symbols.isEmpty && !showEmptyTypes { return nil }
            let sorted = symbols.sorted { $0.index < $1.index }
            return SymbolGroup(type: type, symbols: sorted)
        }
    }

    private func bindingForGroup(_ type: SymbolType) -> Binding<Bool> {
        Binding(
            get: { expandedTypes.contains(type) },
            set: { isExpanded in
                if isExpanded {
                    expandedTypes.insert(type)
                } else {
                    expandedTypes.remove(type)
                }
            }
        )
    }
}

// MARK: - Pieces
private struct MetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: Capsule())
    }
}

private struct SymbolGroup: Identifiable {
    let type: SymbolType
    let symbols: [Symbols]

    var id: String { type.rawValue }
    var count: Int { symbols.count }
}

private struct SymbolGroupView: View {
    let group: SymbolGroup
    @Binding var isExpanded: Bool
    let showIndices: Bool
    let limit: Int
    let onSelect: (Int) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 56), spacing: 6, alignment: .leading)
    ]

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if showIndices {
                let preview = Array(group.symbols.prefix(limit))
                LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                    ForEach(preview, id: \.index) { symbol in
                        Button {
                            onSelect(symbol.index)
                        } label: {
                            Text("\(symbol.index)")
                                .font(.caption2)
                                .monospacedDigit()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                if group.symbols.count > limit {
                    Text("+\(group.symbols.count - limit) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(group.type.rawValue.trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.type.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text("\(group.count) match\(group.count == 1 ? "" : "es")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
