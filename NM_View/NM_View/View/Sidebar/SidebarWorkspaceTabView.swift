//
//  SidebarWorkspaceTabView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/19/26.
//

import SwiftUI
import SwiftData

struct SidebarWorkspaceTabView: View {
    
    @Query var workspaces: [Workspace]
    @Bindable var vm: NMViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Workspaces")
                    .font(.headline)
                Spacer()
                Button {
                    vm.switchScreens(to: .addView)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .help("Add Workspace")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView {
                LazyVStack {
                    ForEach(workspaces) { workspace in
                        Button(action: {
                            vm.selectWorkspace(workspace)
                        }) {
                            SidebarRow(
                                workspace: workspace,
                                isCurrent: Binding(
                                    get: { vm.selectedWorkspace == workspace },
                                    set: { _ in }
                                )
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct SidebarRow: View {
    let workspace: Workspace
    @Binding var isCurrent: Bool
    
    var body: some View {
        Text(workspace.file.lastPathComponent)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity)
            .padding([.vertical, .horizontal], 4)
            .listRowBackground(isCurrent ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
