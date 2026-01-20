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
    
    private static let vimModeDefaultsKey = "NMViewModel.vimModeEnabled"
    private static let sidebarStyleDefaultsKey = "NMViewModel.sidebarStyle"
     
    /// CTX Required for swiftdata sync
    @ObservationIgnored
    var ctx: ModelContext?

    @ObservationIgnored
    internal let nmcore = NMCore()
    
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
    var sidebarStyle: SidebarStyle = .custom {
        didSet {
            UserDefaults.standard.set(sidebarStyle.rawValue, forKey: Self.sidebarStyleDefaultsKey)
        }
    }
    var allowEdit = false
    var isInVimMode = false {
        didSet {
            UserDefaults.standard.set(isInVimMode, forKey: Self.vimModeDefaultsKey)
        }
    }
    
    var searchIndexs: [Int: String] = [:]
    var filterText: String = ""
    /// whatever / 1.0
    var searchPercentageDone: CGFloat?
    
    var highlightCommands: HighlightCommands?
    
    var scanTask: Task<Void, Never>?
    var scanSymbolTask: Task<Void, Never>?
    var searchTask: Task<Void, Never>?

    init() {
        self.isInVimMode = UserDefaults.standard.bool(forKey: Self.vimModeDefaultsKey)
        if let rawValue = UserDefaults.standard.string(forKey: Self.sidebarStyleDefaultsKey) {
            if let style = SidebarStyle(rawValue: rawValue) {
                self.sidebarStyle = style
            } else if rawValue == "swiftUI" || rawValue == "appKit" {
                self.sidebarStyle = .custom
            }
        }
    }
    
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
    
    public func addSearchTerm() {
        guard let selectedWorkspace else { return }
        let term = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        guard !selectedWorkspace.doesSearchTermExist(term) else { return }
        selectedWorkspace.addSearchTerm(term)
        do {
            try ctx?.save()
            print("sav")
        } catch {
            print("Failed to save search term: \(error)")
        }
    }
    
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

enum SidebarStyle: String, CaseIterable, Identifiable {
    case custom
    case navigationSplit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .custom:
            return "Custom"
        case .navigationSplit:
            return "NavigationSplitView"
        }
    }
}
