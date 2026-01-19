//
//  SidebarSearchPanelView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/19/26.
//

import SwiftUI

struct SidebarSearchPanelView: View {
    @Bindable var vm: NMViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            contentView
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Search Results")
                    .font(.headline)
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !vm.searchIndexs.isEmpty {
                Text("\(vm.searchIndexs.count)")
                    .font(.caption)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var contentView: some View {
        if vm.searchIndexs.isEmpty {
            emptyStateView
        } else {
            indexListView
        }
    }

    private var indexListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(sortedSearchRows, id: \.key) { value in
                    Button(action: {
                        vm.goToHighlight(value.key)
                    }) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("#\(value.key)")
                                    .font(.caption2)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                Text(value.value.isEmpty ? "…" : value.value)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            Text("No matches yet")
                .font(.callout)
            Text("Search results will appear here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var subtitleText: String {
        if vm.filterText.isEmpty {
            return "Start typing in the toolbar to search."
        }
        return "Showing matches for “\(vm.filterText)”"
    }

    private var sortedSearchRows: [(key: Int, value: String)] {
        vm.searchIndexs.sorted { $0.key < $1.key }
    }
}
