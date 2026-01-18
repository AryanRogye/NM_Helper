//
//  AddView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/18/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddView: View {
    
    @Bindable var vm: NMViewModel
    @State private var text: String = ""
    @State private var droppedFile: URL?
    @State private var isDropTargeted: Bool = false
    
    var body: some View {
        VStack {
            VStack {
                /// If nothing is dropped
                if let droppedFile {
                    Text(droppedFile.lastPathComponent)
                    
                    Button("Clear Dropped") { self.droppedFile = nil }
                    Button("Create Workspace") {
                        vm.createWorkspace(droppedFile)
                    }
                    
                } else {
                    Text("Drop Something On The Screen")
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
