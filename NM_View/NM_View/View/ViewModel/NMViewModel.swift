//
//  NMViewModel.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/17/26.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class NMViewModel {
     
    /// CTX Required for swiftdata sync
    @ObservationIgnored
    var ctx: ModelContext?
    
    public func bind(to ctx: ModelContext) {
        self.ctx = ctx
    }

    /// Max Chunk size we load in
    @ObservationIgnored
    let chunkSize = 1000

    /// Current Screen
    var currentScreen: Screens = .addView
    
    var selectedWorkspace: Workspace?
    var selectedChunks: [String] = []
    
    var selectedSize: Int? = nil
    var selectedMaxSize: Int? = nil

    var isNMScanning = false
    var isLoadingChunks = false
    
    
}

// MARK: - Workspace
extension NMViewModel {
    public func selectWorkspace(_ workspace: Workspace) {
        
        if selectedWorkspace == workspace { return }
        
        selectedWorkspace = workspace
        currentScreen = .home
    }
    
    public func createWorkspace(_ url: URL) {
        
        guard let ctx else {
            print("CTX NIL")
            return
        }
        let workspace = Workspace(file: url)
        ctx.insert(workspace)
        
        selectedWorkspace = workspace
        currentScreen = .home
    }
}

// MARK: - NM
extension NMViewModel {
    public func nmSelect(_ url: URL) {
        
        if isNMScanning { return }
        if isLoadingChunks { return }
        
        let path = url.path
        isNMScanning = true
        isLoadingChunks = true
        selectedChunks.removeAll()
        selectedMaxSize = nil
        
        Task.detached(priority: .userInitiated) { [path] in
            let result: String = path.withCString { cStr in
                let mut = UnsafeMutablePointer<CChar>(mutating: cStr)
                guard let out = nm_scan_file(mut) else { return "" }
                defer { nm_free(out) }
                return String(cString: out)
            }
            
            await MainActor.run { [result] in
                /// Create a workspace
                self.selectedWorkspace = Workspace(file: url)
                self.selectedMaxSize = result.count
                self.isNMScanning = false
            }
            
            let full = result
            var i = full.startIndex
            
            while i < full.endIndex {
                
                let next = full.index(
                    i,
                    offsetBy: self.chunkSize,
                    limitedBy:
                        full.endIndex
                ) ?? full.endIndex
                
                let chunk = String(full[i..<next])
                i = next
                
                await MainActor.run {
                    print("Appending")
                    self.selectedChunks.append(chunk)
                    self.selectedSize = (self.selectedSize ?? 0) + chunk.count
                }
                
                try? await Task.sleep(nanoseconds: 30_000_000) // 30ms, tweak
            }
            
            await MainActor.run {
                self.isLoadingChunks = false
                print("Done Loading Chunks")
            }
        }
    }
}
