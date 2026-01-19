//
//  WorkspaceView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/18/26.
//

import SwiftUI
import TextEditor

struct WorkspaceView: View {
    
    @Bindable var vm: NMViewModel
    @Bindable var workspace: Workspace
    
    @State private var searchQuery: String = ""
    
    var body: some View {
        rootView
    }
}

// MARK: - Body
extension WorkspaceView {
    private var rootView: some View {
        contentView
            .navigationTitle(workspace.name)
            .toolbar { toolbarContent }
            .toolbarRole(.editor)
    }
}

// MARK: - Content
extension WorkspaceView {
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            if vm.selectedChunks.isEmpty {
                emptyStateView
            } else {
                editorContainerView
            }
            Spacer()
        }
    }
}

// MARK: - Components
extension WorkspaceView {
    private var emptyStateView: some View {
        HStack {
            Text("File: \(workspace.file)")
            Button("Load") {
                vm.nmSelect(workspace.file)
            }
        }
    }
    
    private var editorContainerView: some View {
        ZStack {
            editorView
        }
    }
    
    private var editorView: some View {
        ComfyTextEditor(
            chunks: chunksBinding,
            highlightIndexRows: $vm.searchIndexs,
            filterText: $vm.filterText,
            showScrollbar: .constant(false),
            onHighlightUpdated: { highlight in
                vm.searchPercentageDone = highlight
            },
            onHighlight: { highlightCommands in
                vm.highlightCommands = highlightCommands
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Toolbar
extension WorkspaceView {
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !vm.isLoadingChunks && !vm.selectedChunks.isEmpty {
            ToolbarItem(placement: .automatic) {
                searchFieldView
            }
        }
        if vm.isLoadingChunks,
           let selectedSize = vm.selectedSize,
           let selectedMaxSize = vm.selectedMaxSize {
            ToolbarItem(placement: .automatic) {
                progressToolbarView(selectedSize: selectedSize, selectedMaxSize: selectedMaxSize)
            }
        }
    }
    
    private func progressToolbarView(selectedSize: Int, selectedMaxSize: Int) -> some View {
        ProgressView(value: CGFloat(selectedSize), total: CGFloat(selectedMaxSize)) {
            let percent = (Double(selectedSize) / Double(selectedMaxSize)) * 100
            Text("\(Int(percent))%")
        }
        .progressViewStyle(CircularProgressStyle())
        .frame(width: 60, height: 18)
    }
    
}

// MARK: - Search
extension WorkspaceView {
    private var searchFieldView: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            ZStack(alignment: .trailing) {
                TextField("Search", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .padding(.trailing, searchProgressFraction == nil ? 0 : 52)
                if let progress = searchProgressFraction {
                    searchProgressView(progress: progress)
                        .padding(.trailing, 2)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(width: 220)
        .onChange(of: searchQuery) { _, newValue in
            vm.searchFilter(newValue)
        }
    }

    private var searchProgressFraction: Double? {
        guard !vm.filterText.isEmpty,
              let progress = vm.searchPercentageDone
        else { return nil }
        let clamped = min(max(Double(progress), 0), 1)
        return clamped < 1 ? clamped : nil
    }

    private func searchProgressView(progress: Double) -> some View {
        HStack(spacing: 4) {
            Text(progress, format: .percent.precision(.fractionLength(0)))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize()
            
            ProgressView(value: progress)
                .progressViewStyle(CircularProgressStyle())
                .frame(width: 16, height: 16)
                .opacity(0.9)
        }
    }
}

// MARK: - State
extension WorkspaceView {
    private var chunksBinding: Binding<[String]> {
        Binding(
            get: { vm.selectedChunks },
            set: { vm.selectedChunks = $0 }
        )
    }
}
