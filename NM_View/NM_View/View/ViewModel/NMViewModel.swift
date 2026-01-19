//
//  NMViewModel.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/17/26.
//

import Foundation
import SwiftData
import TextEditor
import nmcore

@Observable
@MainActor
final class NMViewModel {
     
    /// CTX Required for swiftdata sync
    @ObservationIgnored
    var ctx: ModelContext?

    @ObservationIgnored
    private let nmcore = NMCore()
    
    public func bind(to ctx: ModelContext) {
        self.ctx = ctx
    }

    /// Max Chunk size we load in
    @ObservationIgnored
    let chunkSize = 1000

    /// Current Screen
    var currentScreen: Screens = .addView

    var currentIndex: Int?
    
    /// Current Workspace Stuff
    var selectedWorkspace: Workspace?
    var selectedChunks: [String] = []
    
    var selectedWorkspaceSymbols: [Int: Symbols] = [:]
    
    var selectedSize: Int? = nil
    var selectedMaxSize: Int? = nil

    var isNMScanning = false
    var isLoadingChunks = false
    
    var isScanningSymbols = false
    
    var isSidebarVisible = true
    var sidebarTab: SidebarTab = .sidebar
    
    var searchIndexs: [Int: String] = [:]
    var filterText: String = ""
    /// whatever / 1.0
    var searchPercentageDone: CGFloat?
    
    var highlightCommands: HighlightCommands?
    
    var scanTask: Task<Void, Never>?
    var scanSymbolTask: Task<Void, Never>?
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
        self.scanSymbolTask?.cancel()
        self.selectedWorkspace = nil
        self.selectedChunks.removeAll()
        self.selectedSize = nil
        self.selectedMaxSize = nil
        self.isNMScanning = false
        self.isLoadingChunks = false
        self.searchIndexs.removeAll()
        self.filterText = ""
        self.searchPercentageDone = nil
        self.selectedWorkspaceSymbols.removeAll()
        self.isScanningSymbols = false
    }
}

// MARK: - Highlight
extension NMViewModel {
    public func goToHighlight(_ index: Int) {
        highlightCommands?.gotoHighlight(index)
    }
    public func clearHighlight() {
        highlightCommands?.resetHighlightedRanges()
    }
}

// MARK: - Sidebar
extension NMViewModel {
    public func toggleSidebar() {
        isSidebarVisible.toggle()
    }

    public func selectSidebarTab(_ tab: SidebarTab) {
        sidebarTab = tab
    }
}

// MARK: - Search
extension NMViewModel {
    public func searchFilter(_ filter: String) {
        
        searchTask?.cancel()
        self.searchIndexs.removeAll()
        self.clearHighlight()
        
        if filter.isEmpty {
            filterText = ""
            searchPercentageDone = nil
            return
        }
        
        filterText = filter
        let chunks = selectedChunks.joined()
        
        let nmcore = nmcore
        searchTask = Task.detached(priority: .userInitiated) { [weak self] in
            
            
            if Task.isCancelled { return }
            
            let indices = nmcore.grep(filter, in: chunks)
            
            if Task.isCancelled { return }
            guard let self else { return }
            
            await MainActor.run { [indices] in
                for i in indices {
                    self.searchIndexs[i] = ""
                }
                
                if !self.searchIndexs.isEmpty {
                    self.isSidebarVisible = true
                    self.selectSidebarTab(.panel)
                }
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
        
        /// Check if is running, if we are return
        if isNMScanning { return }
        if isLoadingChunks { return }
        
        /// cancel tasks that may be active
        scanTask?.cancel()
        
        /// store path once
        let path = url.path
        
        /// set flags to true locking this function
        isNMScanning = true
        isLoadingChunks = true
        
        /// clear
        selectedChunks.removeAll()
        selectedMaxSize = nil
        selectedWorkspaceSymbols.removeAll(keepingCapacity: true)
        
        /// load a chunk size
        let chunkSize = self.chunkSize
        
        
        let nmcore = nmcore
        scanTask = Task.detached(priority: .userInitiated) { [path] in
            
            /// Set whats gonna happen on exit
            defer {
                Task { @MainActor in
                    self.isNMScanning = false
                    self.isLoadingChunks = false
                    self.isScanningSymbols = false
                }
            }
            
            /// if task is called to get cancelled, cancel it
            if Task.isCancelled { return }
            
            let result: String = nmcore.scanFile(path: path)
            
            /// check again if task got cancelled
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
                /// 10 at a time
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
            
            
            /// now we can start the symbol scan
            await MainActor.run {
                self.isLoadingChunks = false
                self.isScanningSymbols = true
            }
            
            let symbols = SymbolType.allCases.map(\.rawValue)   // [String]
            let count = symbols.count
            
            var foundSymbols: [Symbols] = []
            
            let resultsBySymbol = nmcore.multiGrep(symbols, in: full)
            let nsFull = full as NSString
            for i in 0..<count {
                let type = SymbolType.allCases[i]
                let key = symbols[i]
                let indices = resultsBySymbol[key] ?? []
                for idx in indices {
                    let lineRange = nsFull.lineRange(for: NSRange(location: idx, length: 0))
                    foundSymbols.append(Symbols(symbolType: type, index: lineRange.location))
                }
            }
            
            /// now we can slowly update the ui
            let batchSize = 100
            var start = 0
            let end = foundSymbols.count
            
            while start < end {
                if Task.isCancelled { return }
                
                let next = min(start + batchSize, end)
                let batch = Array(foundSymbols[start..<next])
                start = next
                
                await MainActor.run {
                    for s in batch {
                        self.selectedWorkspaceSymbols[s.index] = s
                    }
                }
                
                // slow it down + let UI breathe
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                // or: await Task.yield()
            }
        }
    }
}
