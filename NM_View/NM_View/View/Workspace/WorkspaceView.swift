//
//  WorkspaceView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/18/26.
//

import SwiftUI
import TextEditor
import nmcore

struct WorkspaceView: View {
    @Bindable var vm: NMViewModel
    @Bindable var workspace: Workspace

    @State private var searchQuery: String = ""
    @State private var currentFlags: [NMFlags] = []
    @State private var isSearchFieldFocused = false

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
        WorkspaceEmptyStateView(
            workspace: workspace,
            currentFlags: $currentFlags,
            onLoad: {
                vm.nmSelect(workspace, flags: currentFlags)
            }
        )
    }

    private var editorContainerView: some View {
        VStack(spacing: 0) {
            
            GeometryReader { geo in
                editorView
                    .frame(
                        width: vm.isInGridMode ? geo.size.width * 0.4 : geo.size.width,
                        height: vm.isInGridMode ? geo.size.height * 0.4 : geo.size.height
                    )
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }

            if vm.isInGridMode {
                
            }
        }
    }

    private var editorView: some View {
        ComfyTextEditor(
            chunks: chunksBinding,
            highlightIndexRows: $vm.searchIndexs,
            filterText: $vm.filterText,
            currentIndex: $vm.currentIndex,
            allowEdit: $vm.allowEdit,
            showScrollbar: .constant(false),
            isInVimMode: $vm.isInVimMode,
            onHighlightUpdated: { highlight in
                vm.searchPercentageDone = highlight
            },
            onHighlight: { highlightCommands in
                vm.highlightCommands = highlightCommands
            },
            onSearchRequested: {
                DispatchQueue.main.async {
                    isSearchFieldFocused = true
                }
            }
        )
    }
}

// MARK: - Toolbar
extension WorkspaceView {
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !vm.isLoadingChunks && !vm.selectedChunks.isEmpty {
            ToolbarItem(placement: .automatic) {
                WorkspaceSearchFieldView(
                    query: $searchQuery,
                    isFocused: $isSearchFieldFocused,
                    progress: searchProgressFraction,
                    onQueryChange: { newValue in
                        vm.searchFilter(newValue)
                    }
                )
            }
        }
        if !vm.doneInitialLoad {
            ToolbarItem(placement: .automatic) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .symbolEffect(.rotate)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.25), value: vm.doneInitialLoad)
                
            }
        }
        if vm.isLoadingChunks,
           let selectedSize = vm.selectedSize,
           let selectedMaxSize = vm.selectedMaxSize {
            ToolbarItem(placement: .automatic) {
                WorkspaceProgressToolbarView(
                    selectedSize: selectedSize,
                    selectedMaxSize: selectedMaxSize
                )
            }
        }
    }
}

// MARK: - Search
extension WorkspaceView {
    private var searchProgressFraction: Double? {
        guard !vm.filterText.isEmpty,
              let progress = vm.searchPercentageDone
        else { return nil }
        let clamped = min(max(Double(progress), 0), 1)
        return clamped < 1 ? clamped : nil
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

#Preview {
    WorkspaceView(vm: NMViewModel(), workspace: Workspace(file: URL(string: "Test")!))
        .frame(width: 800, height: 500)
}
