//
//  SidebarSearchPanelView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/19/26.
//

import SwiftUI

struct SidebarSearchPanelView: View {
    @Bindable var vm: NMViewModel
    @State private var revealedIndex: Int? = nil

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
                    SearchResultRow(
                        index: value.key,
                        line: value.value,
                        revealedIndex: $revealedIndex,
                        onGo: {
                            vm.goToHighlight(value.key)
                        }
                    )
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

private struct SearchResultRow: View {
    let index: Int
    let line: String
    @Binding var revealedIndex: Int?
    let onGo: () -> Void

    private let actionWidth: CGFloat = 56

    private var isRevealed: Bool {
        revealedIndex == index
    }

    private var restingOffset: CGFloat {
        isRevealed ? -actionWidth : 0
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            actionButtons
            rowContent
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isRevealed)
    }

    private var rowContent: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("#\(index)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Text(line.isEmpty ? "…" : line)
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
        .offset(x: restingOffset)
        .onTapGesture {
            revealedIndex = isRevealed ? nil : index
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 0) {
            Button(action: {
                revealedIndex = nil
                onGo()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Go")
                        .font(.caption2)
                }
                .frame(width: actionWidth, height: 44)
                .foregroundStyle(.white)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, 6)
        .opacity(isRevealed ? 1 : 0)
    }
}
