//
//  NMTextView.swift
//  NM_View
//
//  NSTextView wrapper for large, selectable output.
//

import SwiftUI
import AppKit

struct NMTextView: NSViewRepresentable {
    let chunks: [String]

    final class Coordinator {
        var lastChunkCount: Int = 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.drawsBackground = false
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 12, height: 12)

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: CoreFoundation.CGFloat.greatestFiniteMagnitude,
            height: CoreFoundation.CGFloat.greatestFiniteMagnitude
        )

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        if chunks.isEmpty {
            if context.coordinator.lastChunkCount != 0 {
                textView.string = ""
                context.coordinator.lastChunkCount = 0
            }
            return
        }

        let newCount = chunks.count
        let lastCount = context.coordinator.lastChunkCount

        if newCount < lastCount {
            textView.string = chunks.joined()
        } else if newCount > lastCount {
            let newText = chunks[lastCount..<newCount].joined()
            if !newText.isEmpty {
                let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
                let attrs: [NSAttributedString.Key: Any] = [.font: font]
                textView.textStorage?.append(NSAttributedString(string: newText, attributes: attrs))
            }
        }

        context.coordinator.lastChunkCount = newCount
    }
}
