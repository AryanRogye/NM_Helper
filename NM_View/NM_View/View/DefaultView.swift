//
//  DefaultView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/17/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct DefaultView: View {
    
    @Bindable var vm: NMViewModel
    @State private var text: String = ""
    @State private var droppedFile: URL?
    @State private var isDropTargeted: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Drop a file here")
                .font(.title3)
            
            if let selectedWorkspace = vm.selectedWorkspace {
                Text(selectedWorkspace.file.lastPathComponent)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text(droppedFile?.lastPathComponent ?? text)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            if vm.isNMScanning {
                ProgressView()
            }
            
            if let file = droppedFile {
                Button(action: {
                    vm.nmSelect(file)
                }) {
                    Text("Scan this file")
                }
                .disabled(vm.isNMScanning)
            } else if let workspace = vm.selectedWorkspace {
                Button(action: {
                    vm.nmSelect(workspace.file)
                }) {
                    Text("Scan this file")
                }
                .disabled(vm.isNMScanning)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.secondary.opacity(0.06))
                )
                .frame(maxWidth: 420, maxHeight: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    var url: URL?
                    if let data = item as? Data {
                        url = URL(dataRepresentation: data, relativeTo: nil)
                    } else if let fileURL = item as? URL {
                        url = fileURL
                    }
                    if let url = url {
                        DispatchQueue.main.async {
                            droppedFile = url
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}
