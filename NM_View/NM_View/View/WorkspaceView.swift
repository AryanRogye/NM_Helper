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
    
    var body: some View {
        VStack(spacing: 0) {
            if vm.selectedChunks.isEmpty {
                HStack {
                    Text("File: \(workspace.file)")
                    Button("Load") {
                        vm.nmSelect(workspace.file)
                    }
                }
            } else {
                let binding = Binding(
                    get: { vm.selectedChunks },
                    set: { vm.selectedChunks = $0 }
                )
                
                ZStack {
                    ComfyTextEditor(
                        chunks: binding,
                        showScrollbar: .constant(false)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
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
            Spacer()
        }
        .navigationTitle(workspace.name)
        .toolbar {
            if let selectedSize = vm.selectedSize,
                let selectedMaxSize = vm.selectedMaxSize {
                
                ToolbarItem(placement: .automatic) {
                    Text("\(selectedSize)/\(selectedMaxSize)")
                }
            }
        }
    }
}
