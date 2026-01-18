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
    var highlightIndexRows: Binding<[Int]>?
    var filterText: Binding<String>?
    
    var useChunks: Bool
    
    /// TODO: COMMENT
    @Binding var font: CGFloat
    @Binding var magnification: CGFloat
    @Binding var isBold       : Bool
    
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
    
    var onReady: (EditorCommands) -> Void
    var onSave : () -> Void
    
    public final class Coordinator {
        var lastChunkCount: Int = 0
    }

    public init(
        text: Binding<String>,
        chunks: Binding<[String]>,
        useChunks: Bool,
        highlightIndexRows: Binding<[Int]>? = nil,
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
        onSave : @escaping () -> Void = { },
    ) {
        self.useChunks = useChunks
        self.highlightIndexRows = highlightIndexRows
        self.filterText = filterText
        self.onReady = onReady
        self.onSave = onSave
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
    }
    
    
    /// Convenience initializer for simple usage with only text + scrollbar bindings.
    public init(
        text: Binding<String>,
        showScrollbar: Binding<Bool>,
        isInVimMode: Binding<Bool> = .constant(false),
        editorBackground: Color = .white,
        editorForegroundStyle: Color = .black,
        borderColor: Color = Color.gray.opacity(0.3),
        borderRadius: CGFloat = 8
    ) {
        self.init(
            text: text,
            chunks: .constant([]),
            useChunks: false,
            highlightIndexRows: nil,
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
            onSave: { }
        )
    }
    
    /// Convenience initializer for simple usage with only text + scrollbar bindings.
    public init(
        chunks: Binding<[String]>,
        highlightIndexRows: Binding<[Int]>? = nil,
        filterText: Binding<String>? = nil,
        showScrollbar: Binding<Bool>,
        isInVimMode: Binding<Bool> = .constant(false),
        editorBackground: Color = .white,
        editorForegroundStyle: Color = .black,
        borderColor: Color = Color.gray.opacity(0.3),
        borderRadius: CGFloat = 8
    ) {
        self.init(
            text: .constant(""),
            chunks: chunks,
            useChunks: true,
            highlightIndexRows: highlightIndexRows,
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
            onSave: { }
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
        
        /// Observe Text Changes
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
                let indices = highlightIndexRows.wrappedValue
                if indices != highlightModel.indices {
                    highlightModel.resetHighlightedRanges()
                    highlightModel.indices = highlightIndexRows.wrappedValue
                    highlightModel.indices.forEach {
                        highlightModel.highlight($0, filterText: filterText.wrappedValue)
                    }
                }
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
    }
}
