//
//  NMViewModel+NM.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/19/26.
//

import Foundation
import nmcore

// MARK: - NM
extension NMViewModel {
    
    public func nmSelect(_ workspace: Workspace, flags: [NMFlags]) {
        
        /// Check if is running, if we are return
        if isNMScanning { return }
        if isLoadingChunks { return }
        
        /// cancel tasks that may be active
        scanTask?.cancel()
        
        /// store path once
        let path = workspace.file.path
        
        /// set flags to true locking this function
        isNMScanning = true
        isLoadingChunks = true
        
        /// clear
        doneInitialLoad = false
        selectedChunks.removeAll()
        selectedMaxSize = nil
        selectedWorkspaceSymbols.removeAll(keepingCapacity: true)
        
        /// load a chunk size
        let chunkSize = self.chunkSize
        let flags = flags
        
        
        selectedWorkspace = workspace
        
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
            
            /// NM Scan
            do {
                
                /// if task is called to get cancelled, cancel it
                if Task.isCancelled { return }
                
                let result = try await nmcore.scanFile(path: path, options: flags)
                await MainActor.run {
                    self.doneInitialLoad = true
                }
                
                /// check again if task got cancelled
                if Task.isCancelled { return }
                
                await MainActor.run { [result] in
                    self.selectedMaxSize = result.count
                    /// Scanning is done, chunking still remains
                    self.isNMScanning = false
                }
                
                await self.updateChunksUI(result: result, chunkSize: chunkSize)
                await self.scanSymbols(result: result)

            } catch is CancellationError {
                print("Returning Cuz of Cancellation Error")
                return
            } catch {
                print("Returning Cuz of Error: \(error)")
                return
            }
        }
    }
    
    nonisolated private func scanSymbols(result: String) async {
        do {
            /// now we can start the symbol scan
            await MainActor.run {
                self.isLoadingChunks = false
                self.isScanningSymbols = true
            }
            
            let symbols = SymbolType.allCases.map(\.rawValue)   // [String]
            let count = symbols.count
            
            var foundSymbols: [Symbols] = []
            
            let resultsBySymbol = nmcore.multiGrep(symbols, in: result)
            let nsFull = result as NSString
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
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                // or: await Task.yield()
            }
        } catch {
            
        }
    }
    
    nonisolated private func updateChunksUI(result: String, chunkSize: Int) async {
        do {
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
                    if Task.isCancelled { return }
                    self.selectedChunks.append(contentsOf: batch)
                    self.selectedSize = (self.selectedSize ?? 0) + batchSize
                }
                
                try await Task.sleep(nanoseconds: 10_000_000) // 30ms, tweak
            }
        } catch {
            
        }
    }
}
