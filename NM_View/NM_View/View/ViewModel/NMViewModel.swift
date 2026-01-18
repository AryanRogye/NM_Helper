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
    
    /// Current Workspace Stuff
    var selectedWorkspace: Workspace?
    var selectedChunks: [String] = []
    
    var selectedSize: Int? = nil
    var selectedMaxSize: Int? = nil

    var isNMScanning = false
    var isLoadingChunks = false
    
    var searchIndexs: [Int] = []

    var scanTask: Task<Void, Never>?
    var searchTask: Task<Void, Never>?
    
    /// Switch Screen
    public func switchScreens(to screen: Screens) {
        
        /// if on home, and screen requested is add, and we have a task thats started
        if currentScreen == .home,
           screen == .addView {
            self.clearWorkspace()
        }
        
        currentScreen = screen
    }
    
    /// Clear Workspace
    private func clearWorkspace() {
        self.scanTask?.cancel()
        self.searchTask?.cancel()
        self.selectedWorkspace = nil
        self.selectedChunks.removeAll()
        self.selectedSize = nil
        self.selectedMaxSize = nil
        self.isNMScanning = false
        self.isLoadingChunks = false
        self.searchIndexs.removeAll()
    }
}

// MARK: - Search
extension NMViewModel {
    public func searchFilter(_ filter: String) {
        
        if filter.isEmpty { return }
        searchTask?.cancel()
        self.searchIndexs.removeAll()
        
        let chunks = selectedChunks.joined()
        
        searchTask = Task.detached(priority: .userInitiated) { [weak self] in
            
            if Task.isCancelled { return }
            
            var indices : [Int] = []
            /// Convert to C String
            filter.withCString { cStr in
                chunks.withCString { searchCStr in
                    
                    var outSize: Int32 = 0

                    if let ptr = nm_grep(
                        UnsafeMutablePointer<CChar>(mutating: searchCStr),
                        UnsafeMutablePointer<CChar>(mutating: cStr),
                        &outSize
                    ) {
                        
                        for i in 0..<Int(outSize) {
                            indices.append(Int(ptr[i]))
                        }
                        free(ptr)
                    }
                }
            }
            
            if Task.isCancelled { return }
            guard let self else { return }
            
            await MainActor.run { [indices] in
                self.searchIndexs = indices
                print("Updated Search Index's Count: \(indices.count)")
            }
        }
    }
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
        
        scanTask?.cancel()
        
        let path = url.path
        isNMScanning = true
        isLoadingChunks = true
        selectedChunks.removeAll()
        selectedMaxSize = nil
        
        let chunkSize = self.chunkSize
        
        scanTask = Task.detached(priority: .userInitiated) { [path] in
            
            /// Set whats gonna happen on exit
            defer {
                Task { @MainActor in
                    self.isNMScanning = false
                    self.isLoadingChunks = false
                }
            }
            
            /// Cancel task
            if Task.isCancelled { return }
            
            let result: String = path.withCString { cStr in
                let mut = UnsafeMutablePointer<CChar>(mutating: cStr)
                guard let out = nm_scan_file(mut) else { return "" }
                defer { nm_free(out) }
                return String(cString: out)
            }
            
            if Task.isCancelled { return }

            await MainActor.run { [result] in
                /// Create a workspace
                self.selectedWorkspace = Workspace(file: url)
                self.selectedMaxSize = result.count
                
                /// Scanning is done, chunking still remains
                self.isNMScanning = false
            }
            
            
            let full = result
            var i = full.startIndex
            
            while i < full.endIndex {
                
                if Task.isCancelled { return }
                
                var batch: [String] = []
                var batchSize = 0
                let batchCount = 10
                
                for _ in 0..<batchCount {
                    
                    if Task.isCancelled { return }
                    
                    let next = full.index(
                        i,
                        offsetBy: chunkSize,
                        limitedBy:
                            full.endIndex
                    ) ?? full.endIndex
                    
                    let chunk = String(full[i..<next])
                    i = next
                    batch.append(chunk)
                    batchSize += chunk.count
                }
                
                await MainActor.run { [batch, batchSize] in
                    self.selectedChunks.append(contentsOf: batch)
                    self.selectedSize = (self.selectedSize ?? 0) + batchSize
                }
                
                try? await Task.sleep(nanoseconds: 10_000_000) // 30ms, tweak
            }
            
            await MainActor.run {
                self.isLoadingChunks = false
            }
        }
    }
}
