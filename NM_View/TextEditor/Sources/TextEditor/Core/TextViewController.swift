//
//  TextViewController.swift
//  ComfyEditor
//
//  Created by Aryan Rogye on 12/2/25.
//

import AppKit
import Combine
import SwiftUI

public class TextViewController: NSViewController, EditorCommands {

    /// macOS Given font manager
    let fontManager = NSFontManager.shared

    let vimEngine = VimEngine()

    // MARK: - View's
    /// Our Implementation of a NSScrollView
    /// Lets us hook into `new delegates`
    let scrollView = ComfyScrollView()
    /// Our Implementation of a NSTextView
    lazy var textView = ComfyTextView(vimEngine: vimEngine)
    
    let highlightModel: HighlightModel

    /// Foreground Style
    let foregroundStyle: Color
    /// Bottom Bar for Vim Command Input, etc
    lazy var vimBottomView = VimBottomView(
        vimEngine: vimEngine,
        foregroundStyle: foregroundStyle
    )

    // MARK: - Delegates
    /// Text Delegate
    let textViewDelegate : TextViewDelegate
    /// Magnification Delegate
    let magnificationDelegate : MagnificationDelegate

    /// Flag to know if the app is focussed or not
    internal var isAppActive: Bool {
        NSApplication.shared.isActive
    }
    
    
    // MARK: - Init
    init(
        foregroundStyle       : Color,
        textViewDelegate      : TextViewDelegate,
        magnificationDelegate : MagnificationDelegate,
        highlightModel          : HighlightModel,
        onSave                : @escaping () -> Void
    ) {
        self.foregroundStyle = foregroundStyle
        self.textViewDelegate = textViewDelegate
        self.magnificationDelegate = magnificationDelegate
        self.highlightModel = highlightModel
        
        super.init(nibName: nil, bundle: nil)
        
        highlightModel.updateHighlightedRanges = updateHighlightedRanges
        highlightModel.resetHighlightedRanges = resetHighlightedRanges

        /// Assign On Save Values
        vimEngine.onSave = onSave
        
        /// Assign VimEngine
        textViewDelegate.vimEngine = vimEngine
        
        /// On Updating Insertion Point we should let the textViewDelegate refresh
        vimEngine.buffer.onUpdateInsertionPoint = {
            textViewDelegate.refresh()
        }
    }
    
    public func updateHighlightedRanges(range: NSRange, filterText: String) {
        self.textView.updateHighlightedRanges(range: range, filterText: filterText)
    }
    public func resetHighlightedRanges() {
        self.textView.resetHighlightedRanges()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
//        EditorCommandCenter.shared.currentEditor = self

        /// Helps when the text editor is brought back into view
        /// for some reason if the request is:
        ///     NavigationLink -> NSViewControllerRepresentable -> NSViewController
        ///     without the following, nothing would show
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.view.window?.makeFirstResponder(self.textView)
        }
    }

    // MARK: - Load View
    public override func loadView() {
        let root = NSView()
        // Enable layer for consistent layer-backed view hierarchy
        root.wantsLayer = true
        self.view = root

        /// Assign ScrollView Delegate
        scrollView.magnificationDelegate = magnificationDelegate

        /// Assign TextView delegate's
        textView.delegate = textViewDelegate
        textView.setupCursorView()

        // Use RedrawClipView for optimized redrawing during zoom
        scrollView.contentView = RedrawClipView()
        scrollView.documentView = textView
        root.addSubview(scrollView)
        root.addSubview(vimBottomView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: root.topAnchor),
            // instead of pinning scroll bottom to root:
            scrollView.bottomAnchor.constraint(equalTo: vimBottomView.topAnchor),
        ])
        NSLayoutConstraint.activate([
            vimBottomView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            vimBottomView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            vimBottomView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            vimBottomView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    public func setCornerRadius(_ value: CGFloat) {
        view.layer?.cornerRadius = value
    }

    /// Sets the background color for the entire editor area
    public func setEditorBackground(_ color: NSColor) {
        view.layer?.backgroundColor = color.cgColor
        scrollView.setScrollBackground(color)
    }
}

// MARK: - Bold
extension TextViewController {
    /// Public Function to toggle bold
    /// Could be on selection OR entire editor
    ///     Currently set to 1 or the other
    ///     TODO: Maybe have a "Bold on Selection, Configures"
    public func toggleBold() {
        guard isAppActive else { return }
        textViewDelegate.toggleBold(in: textView)
    }
}

// MARK: - Increase / Decrease Font
extension TextViewController {

    /// Public function to increase the font or zoom in
    /// If is selecting something, then it increases the font under it
    /// if is not, then zooms in
    public func increaseFontOrZoomIn() {
        guard isAppActive else { return }

        if let range = textViewDelegate.range, range.length > 0 {
            guard let storage = textView.textStorage else { return }
            updateFont(range, storage: storage, increase: true)
            textViewDelegate.forceFontRefresh(textView: textView)
        } else {
            let newMag = scrollView.magnification + 0.1
            scrollView.setZoom(newMag)
        }
    }

    /// Public function to increase the font or zoom in
    /// If is selecting something, then it decreases the font under it
    /// if is not, then zooms out
    public func decreaseFontOrZoomOut() {
        guard isAppActive else { return }

        if let range = textViewDelegate.range, range.length > 0 {
            guard let storage = textView.textStorage else { return }
            updateFont(range, storage: storage, increase: false)
            textViewDelegate.forceFontRefresh(textView: textView)
        } else {
            let newMag = scrollView.magnification - 0.1
            scrollView.setZoom(newMag)
        }
    }

    /// Internal function to update the font, is useful while increasing/decreasing font
    internal func updateFont(_ range: NSRange, storage: NSTextStorage, increase: Bool) {
        storage.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            guard let font = value as? NSFont else { return }

            let delta: CGFloat = increase ? 1.0 : -1.0
            let newSize = max(1, font.pointSize + delta)

            let newFont = fontManager.convert(font, toSize: newSize)
            storage.addAttribute(.font, value: newFont, range: subRange)
        }
    }
}
