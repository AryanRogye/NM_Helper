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
            loadingOverlayView
        }
    }
    
    private var editorView: some View {
        ComfyTextEditor(
            chunks: chunksBinding,
            highlightIndexRows: $vm.searchIndexs,
            showScrollbar: .constant(false)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var loadingOverlayView: some View {
        if vm.selectedChunks.isEmpty && vm.isLoadingChunks {
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading symbols…")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
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
            TextField("Search", text: $searchQuery)
                .textFieldStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(width: 220)
        .onChange(of: searchQuery) { _, newValue in
            vm.searchFilter(newValue)
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
