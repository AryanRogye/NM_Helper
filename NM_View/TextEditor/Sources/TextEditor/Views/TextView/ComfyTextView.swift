//
//  ComfyTextView.swift
//  ComfyEditor
//
//  Created by Aryan Rogye on 12/2/25.
//

import AppKit
import LocalShortcuts
import SwiftUI

final class ComfyTextView: NSTextView {

    override var insertionPointColor: NSColor? {
        get { .controlAccentColor }
        set { /* ignore external changes */  }
    }

    var vimEngine: VimEngine

    lazy var vimCursorView: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(Color.accentColor.opacity(0.5)).cgColor
        v.isHidden = true  // Hide until first update
        return v
    }()

    public func setupCursorView() {
        self.addSubview(vimCursorView)
    }
    
    public func updateHighlightedRanges(range: NSRange) {
        guard let storage = self.textStorage else { return }
        
        var lineRange: NSRange?
        
        storage.beginEditing()
        if range.location >= 0, range.location + range.length <= storage.length {
            let lr = (storage.string as NSString).lineRange(for: range)
            storage.addAttribute(.backgroundColor,
                                 value: NSColor.selectedTextBackgroundColor.withAlphaComponent(0.4),
                                 range: lr)
            lineRange = lr
        }
        storage.endEditing()
    }

    
    public func resetHighlightedRanges() {
        guard let storage = self.textStorage else { return }
        let full = NSRange(location: 0, length: storage.length)
        storage.removeAttribute(.backgroundColor, range: full)
    }


    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        // If the blink cycle is off, don't draw anything
        guard flag else { return }

        /// if User is not using vim mode then draw regular
        if !vimEngine.isInVimMode {
            super.drawInsertionPoint(in: rect, color: color, turnedOn: flag)
            return
        }
        handleVimInsertionPoint(rect, color)
    }

    override func keyDown(with event: NSEvent) {
        if vimEngine.isInVimMode {
            if vimEngine.handleVimEvent(event) {
                /// if vimEvent is ok to type then we can type
                super.keyDown(with: event)
            }
            return
        }
        super.keyDown(with: event)
    }

    init(vimEngine: VimEngine) {

        self.vimEngine = vimEngine

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()

        let textContainer = NSTextContainer()

        textContainer.widthTracksTextView = false
        textContainer.heightTracksTextView = false
        textContainer.containerSize = NSSize(
            width: CoreFoundation.CGFloat.greatestFiniteMagnitude,
            height: CoreFoundation.CGFloat.greatestFiniteMagnitude
        )

        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        super.init(frame: .zero, textContainer: textContainer)
        self.vimEngine.buffer.setTextView(self)

        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay

        isVerticallyResizable = true
        isHorizontallyResizable = true
        autoresizingMask = [.height]
        textContainerInset = .zero

        maxSize = NSSize(
            width: CoreFoundation.CGFloat.greatestFiniteMagnitude,
            height: CoreFoundation.CGFloat.greatestFiniteMagnitude
        )

        font = NSFont(name: "SF Mono", size: 10)
        isEditable = true
        isSelectable = true
        isRichText = true
        allowsDocumentBackgroundColorChange = true
        usesFontPanel = true
        usesRuler = true
        
        // Disable NSTextView's own background drawing to prevent white tearing
        // Background will be drawn via layer instead
        drawsBackground = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
