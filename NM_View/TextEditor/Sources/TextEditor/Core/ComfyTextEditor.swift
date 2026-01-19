//
//  Editor.swift
//  ComfyEditor
//
//  Created by Aryan Rogye on 12/2/25.
//

import SwiftUI

public struct ComfyTextEditor: NSViewControllerRepresentable {
    

    @State private var highlightModel = HighlightModel()
    /// Text to type into
    @Binding var text: String
    @Binding var chunks: [String]
    var highlightIndexRows: Binding<[Int: String]>?
    var filterText: Binding<String>?
    
    var useChunks: Bool
    
    /// TODO: COMMENT
    @Binding var font: CGFloat
    @Binding var magnification: CGFloat
    @Binding var isBold       : Bool
    
    var currentIndex: Binding<Int?>
    @Binding var allowEdit: Bool
    
    /// Boolean if is in VimMode or not
    @Binding var isInVimMode: Bool
    /// Boolean if is showing scrollbar or not
    @Binding var showScrollbar: Bool
    /// Color of the editor background
    var editorBackground: Color
    /// Color of the text
    var editorForegroundStyle: Color
    /// Color of the border
    var borderColor: Color
    /// Border Radius of the entire editor
    var borderRadius: CGFloat
    
    let textViewDelegate = TextViewDelegate()
    let magnificationDelegate = MagnificationDelegate()
    
    var onHighlight: (HighlightCommands) -> Void
    var onReady: (EditorCommands) -> Void
    var onSave : () -> Void
    var onHighlightUpdated: (CGFloat) -> Void
    var onSearchRequested: () -> Void
    
    public final class Coordinator {
        var lastChunkCount: Int = 0
    }

    public init(
        text: Binding<String>,
        chunks: Binding<[String]>,
        useChunks: Bool,
        highlightIndexRows: Binding<[Int: String]>? = nil,
        currentIndex: Binding<Int?> = .constant(nil),
        allowEdit: Binding<Bool> = .constant(false),
        filterText: Binding<String>? = nil,
        font: Binding<CGFloat> = .constant(0),
        isBold: Binding<Bool>,
        magnification: Binding<CGFloat> = .constant(1),
        showScrollbar: Binding<Bool>,
        borderRadius: CGFloat = 8,
        isInVimMode: Binding<Bool> = .constant(false),
        editorBackground: Color = .white,
        editorForegroundStyle: Color = .black,
        borderColor: Color = Color.gray.opacity(0.3),
        onReady: @escaping (EditorCommands) -> Void = { _ in },
        onHighlight: @escaping (HighlightCommands) -> Void = { _ in },
        onSave : @escaping () -> Void = { },
        onHighlightUpdated: @escaping (CGFloat) -> Void = { _ in },
        onSearchRequested: @escaping () -> Void = { }
    ) {
        self.useChunks = useChunks
        self.highlightIndexRows = highlightIndexRows
        self.filterText = filterText
        self.onReady = onReady
        self.onSave = onSave
        self.onSearchRequested = onSearchRequested
        self._text = text
        self._chunks = chunks
        self._font = font
        self._magnification = magnification
        self._isBold = isBold
        self._showScrollbar = showScrollbar
        self._isInVimMode = isInVimMode
        self.editorBackground = editorBackground
        self.editorForegroundStyle = editorForegroundStyle
        self.borderRadius = borderRadius
        self.borderColor = borderColor
        self.onHighlightUpdated = onHighlightUpdated
        self.onHighlight = onHighlight
        self.currentIndex = currentIndex
        self._allowEdit = allowEdit
    }
    
    @State private var updateHighlightTask : Task<Void, Never>? = nil
    @State private var lineCacheTask: Task<Void, Never>? = nil
    
    
    /// Convenience initializer for simple usage with only text + scrollbar bindings.
    public init(
        text: Binding<String>,
        showScrollbar: Binding<Bool>,
        allowEdit: Binding<Bool> = .constant(false),
        isInVimMode: Binding<Bool> = .constant(false),
        editorBackground: Color = .white,
        editorForegroundStyle: Color = .black,
        borderColor: Color = Color.gray.opacity(0.3),
        borderRadius: CGFloat = 8,
        onSearchRequested: @escaping () -> Void = { }
    ) {
        self.init(
            text: text,
            chunks: .constant([]),
            useChunks: false,
            highlightIndexRows: nil,
            allowEdit: allowEdit,
            filterText: nil,
            font: .constant(0),
            isBold: .constant(false),
            magnification: .constant(1),
            showScrollbar: showScrollbar,
            borderRadius: borderRadius,
            isInVimMode: isInVimMode,
            editorBackground: editorBackground,
            editorForegroundStyle: editorForegroundStyle,
            borderColor: borderColor,
            onReady: { _ in },
            onSave: { },
            onSearchRequested: onSearchRequested
        )
    }
    
    /// Convenience initializer for simple usage with only text + scrollbar bindings.
    public init(
        chunks: Binding<[String]>,
        highlightIndexRows: Binding<[Int: String]>? = nil,
        filterText: Binding<String>? = nil,
        currentIndex: Binding<Int?> = .constant(nil),
        allowEdit: Binding<Bool> = .constant(false),
        showScrollbar: Binding<Bool>,
        isInVimMode: Binding<Bool> = .constant(false),
        editorBackground: Color = .white,
        editorForegroundStyle: Color = .black,
        borderColor: Color = Color.gray.opacity(0.3),
        borderRadius: CGFloat = 8,
        onHighlightUpdated: @escaping (CGFloat) -> Void = { _ in },
        onHighlight: @escaping (HighlightCommands) -> Void = { _ in },
        onSearchRequested: @escaping () -> Void = { }
    ) {
        self.init(
            text: .constant(""),
            chunks: chunks,
            useChunks: true,
            highlightIndexRows: highlightIndexRows,
            currentIndex: currentIndex,
            allowEdit: allowEdit,
            filterText: filterText,
            font: .constant(0),
            isBold: .constant(false),
            magnification: .constant(1),
            showScrollbar: showScrollbar,
            borderRadius: borderRadius,
            isInVimMode: isInVimMode,
            editorBackground: editorBackground,
            editorForegroundStyle: editorForegroundStyle,
            borderColor: borderColor,
            onReady: { _ in },
            onHighlight: onHighlight,
            onSave: { },
            onHighlightUpdated: onHighlightUpdated,
            onSearchRequested: onSearchRequested
        )
    }
    
    public func makeNSViewController(context: Context) -> TextViewController {
        let viewController = TextViewController(
            foregroundStyle       : editorForegroundStyle,
            textViewDelegate      : textViewDelegate,
            magnificationDelegate : magnificationDelegate,
            highlightModel        : highlightModel,
            onSave                : onSave
        )
        onReady(viewController)
        onHighlight(viewController)
        if useChunks {
            viewController.textView.string = chunks.joined()
            context.coordinator.lastChunkCount = chunks.count
        } else {
            viewController.textView.string = text
        }
        viewController.textView.layer?.backgroundColor = NSColor(editorBackground).cgColor
        viewController.setEditorBackground(NSColor(editorBackground))
        viewController.vimBottomView.setBackground(color: NSColor(editorBackground))
        viewController.textView.textColor = NSColor(editorForegroundStyle)
        viewController.vimBottomView.setBorderColor(color: NSColor(borderColor))
        viewController.textView.isEditable = allowEdit
        
        viewController.textView.isEditable = true
        viewController.textView.isSelectable = true
        viewController.vimEngine.onSearchRequested = onSearchRequested

        /// Observe Text Changes
        textViewDelegate.observeCurrentIndex(currentIndex)
        textViewDelegate.observeAllowEdit($allowEdit)
        textViewDelegate.observeTextChange($text)
        textViewDelegate.observeFontChange($font)
        textViewDelegate.observeBoldUnderCursor($isBold)
        magnificationDelegate.observeMagnification($magnification)
        
        return viewController
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func updateNSViewController(_ nsViewController: TextViewController, context: Context) {
        
        
        if useChunks {
            
            if let highlightIndexRows, let filterText {
                let indices = highlightIndexRows.wrappedValue.keys.sorted()
                if indices != highlightModel.indices {
                    
                    updateHighlightTask?.cancel()
                    
                    highlightModel.resetHighlightedRanges()
                    highlightModel.indices = indices
                    let indices = highlightModel.indices
                    
                    DispatchQueue.main.async {
                        updateHighlightTask = Task.detached(priority: .userInitiated) {
                            
                            var start = 0
                            var batchSize = 300
                            let total = indices.count
                            
                            while start < total {
                                /// if task cancelled return
                                if Task.isCancelled { return }
                                
                                /// end index is wherever we start + size of batch
                                var end = start + batchSize
                                
                                /// normalize end if it needs to
                                if end > indices.count {
                                    end = indices.count
                                }
                                
                                /// assign batch
                                let batch = indices[start..<end]
                                
                                
                                let ui_update_started = CFAbsoluteTimeGetCurrent()
                                await MainActor.run {
                                    for b in batch {
                                        nsViewController.updateHighlightedRanges(
                                            index: b,
                                            filterText: filterText.wrappedValue
                                        )
                                    }
                                }
                                let ui_update_ended = (CFAbsoluteTimeGetCurrent() - ui_update_started) * 1000.0
                                
                                if ui_update_ended < 6 && batchSize < 2000 {
                                    batchSize *= 2
                                } else if ui_update_ended > 14, batchSize > 50 {
                                    batchSize /= 2
                                }
                                
                                /// set start
                                start = end
                                
                                /// Calculate how many we did, start should be how much we have done till now
                                let progress = CGFloat(start) / CGFloat(total)
                                await MainActor.run {
                                    onHighlightUpdated(progress)
                                }

                                try? await Task.sleep(nanoseconds: 10_000_000) // 30ms, tweak
                            }
                        }
                    }
                    
                }

                populateHighlightLinesIfNeeded(
                    highlightIndexRows: highlightIndexRows,
                    text: nsViewController.textView.string
                )
            }
            
            let newCount = chunks.count
            let lastCount = context.coordinator.lastChunkCount
            
            if newCount == 0 && lastCount != 0 {
                nsViewController.textView.string = ""
                context.coordinator.lastChunkCount = 0
            } else if newCount < lastCount {
                nsViewController.textView.string = chunks.joined()
                context.coordinator.lastChunkCount = newCount
            } else if newCount > lastCount {
                let newText = chunks[lastCount..<newCount].joined()
                if !newText.isEmpty {
                    if let storage = nsViewController.textView.textStorage {
                        let font = nsViewController.textView.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
                        let attrs: [NSAttributedString.Key: Any] = [.font: font]
                        storage.append(NSAttributedString(string: newText, attributes: attrs))
                    } else {
                        nsViewController.textView.string += newText
                    }
                }
                context.coordinator.lastChunkCount = newCount
            }
        }
        

        /// Update if is inVimMode or not
        if nsViewController.vimEngine.isInVimMode != isInVimMode {
            DispatchQueue.main.async {
                nsViewController.vimEngine.isInVimMode = isInVimMode

                /// Update's the insertion point
                nsViewController.textView.updateInsertionPointStateAndRestartTimer(true)

            }
        }
        
        nsViewController.vimEngine.onSearchRequested = onSearchRequested

        if nsViewController.scrollView.hasVerticalScroller != showScrollbar {
            nsViewController.scrollView.hasVerticalScroller = showScrollbar
        }

        if nsViewController.textView.layer?.backgroundColor != NSColor(editorBackground).cgColor {
            nsViewController.textView.layer?.backgroundColor = NSColor(editorBackground).cgColor
            nsViewController.setEditorBackground(NSColor(editorBackground))
        }

        if nsViewController.vimBottomView.layer?.backgroundColor
            != NSColor(editorBackground).cgColor
        {
            nsViewController.vimBottomView.setBackground(color: NSColor(editorBackground))
        }

        if nsViewController.textView.textColor != NSColor(editorForegroundStyle) {
            nsViewController.vimBottomView.setForegroundStyle(color: editorForegroundStyle)
            nsViewController.textView.textColor = NSColor(editorForegroundStyle)
        }

        if nsViewController.vimBottomView.layer?.borderColor != NSColor(borderColor).cgColor {
            nsViewController.vimBottomView.setBorderColor(color: NSColor(borderColor))
        }

        if !nsViewController.textView.isEditable {
            nsViewController.textView.isEditable = true
        }
        if !nsViewController.textView.isSelectable {
            nsViewController.textView.isSelectable = true
        }
    }

    private func populateHighlightLinesIfNeeded(
        highlightIndexRows: Binding<[Int: String]>,
        text: String
    ) {
        let current = highlightIndexRows.wrappedValue
        let missing = current.filter { $0.value.isEmpty }.map { $0.key }
        guard !missing.isEmpty else { return }

        let keysSnapshot = Set(current.keys)
        let textSnapshot = text

        lineCacheTask?.cancel()
        
        DispatchQueue.main.async {
            lineCacheTask = Task.detached(priority: .userInitiated) {
                var updated = current
                let nsText = textSnapshot as NSString
                
                for index in missing {
                    guard index >= 0, index < nsText.length else { continue }
                    let range = nsText.lineRange(for: NSRange(location: index, length: 0))
                    let line = nsText.substring(with: range)
                        .trimmingCharacters(in: .newlines)
                    updated[index] = line
                }
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    guard Set(highlightIndexRows.wrappedValue.keys) == keysSnapshot else { return }
                    highlightIndexRows.wrappedValue = updated
                }
            }
        }
    }
}
