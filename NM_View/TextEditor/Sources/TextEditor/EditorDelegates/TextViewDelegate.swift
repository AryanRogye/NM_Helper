//
//  TextViewDelegate.swift
//  ComfyEditor
//
//  Created by Aryan Rogye on 12/2/25.
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class TextViewDelegate: NSObject, NSTextViewDelegate, ObservableObject {

    @Published var range: NSRange?

    weak var vimEngine: VimEngine?
    weak var textView: NSTextView?
    let fontManager = NSFontManager.shared

    var currentIndex: Binding<Int?> = .constant(0)
    var text: Binding<String> = .constant("")
    var font: Binding<CGFloat> = .constant(0)
    var isBold: Binding<Bool> = .constant(false)
    var allowEdit: Binding<Bool> = .constant(true)
    
    public func observeCurrentIndex(_ val: Binding<Int?>) {
        self.currentIndex = val
    }
    public func observeAllowEdit(_ val: Binding<Bool>) {
        self.allowEdit = val
    }
    public func observeTextChange(_ val: Binding<String>) {
        self.text = val
    }
    public func observeFontChange(_ val: Binding<CGFloat>) {
        self.font = val
    }
    public func observeBoldUnderCursor(_ val: Binding<Bool>) {
        self.isBold = val
    }
    
    public func refresh() {
        guard let textView else { return }
        calculateRange(textView)
    }

    func textView(
        _ textView: NSTextView, clickedOn cell: any NSTextAttachmentCellProtocol,
        in cellFrame: NSRect, at charIndex: Int
    ) {
        self.textView = textView
        calculateRange(textView)
        guard let vimEngine else { return }
        vimEngine.updatePosition()
    }
    
    public func textDidChange(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView else { return }
        self.textView = tv
        // write AppKit -> SwiftUI
        if text.wrappedValue != tv.string {
            text.wrappedValue = tv.string
        }
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        self.textView = textView
        calculateRange(textView)
        guard let vimEngine else { return }
        vimEngine.updatePosition()
    }

    func textView(
        _ textView: NSTextView,
        shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
    ) -> Bool {
        allowEdit.wrappedValue
    }

    /// Calulating Range is the same as when our cursor updates
    private func calculateRange(_ textView: NSTextView) {
        let range: NSRange = textView.selectedRange
        
        let nsText = textView.string as NSString
        if nsText.length == 0 {
            self.currentIndex.wrappedValue = 0
        } else {
            let safeLocation = min(range.location, nsText.length - 1)
            let lineRange = nsText.lineRange(for: NSRange(location: safeLocation, length: 0))
            self.currentIndex.wrappedValue = lineRange.location
        }
        
        let hasSelection = range.length > 0
        // Use hasSelection (e.g., update UI, enable actions, etc.)
        if hasSelection {
            /// Set range of selection here
            self.range = range
            
            forceFontRefresh(textView: textView)
            if let textStorage = textView.textStorage {
                let (bolded, _, _) = isCurrentlyBold(range, in: textStorage)
                self.isBold.wrappedValue = bolded
            }
        } else {
            /// if nothing selected, we nullify range
            self.range = nil
            forceFontRefresh(textView: textView)
            let (bolded, _, _) = isCurrentlyBold(in: textView)
            self.isBold.wrappedValue = bolded
        }
    }
    
    public func forceFontRefresh(textView: NSTextView) {
        if let f = getCurrentFont(textView: textView) {
            font.wrappedValue = f
        }
    }
    
    public func getCurrentFont(textView: NSTextView) -> CGFloat? {

        /// if User is Selecting something, AND range > 0
        if let range = range, range.length > 0, let storage = textView.textStorage {
            var isUniform = false
            var nsFont: NSFont?

            storage.enumerateAttribute(.font, in: range, options: .longestEffectiveRangeNotRequired)
            { value, subRange, stop in
                // If the first run covers the whole range, it's all one font.
                isUniform = (subRange == range)
                nsFont = value as? NSFont

                // Stop immediately; we don't need to look further.
                stop.pointee = true
            }
            if isUniform {
                return nsFont?.pointSize
            } else {
                return nil
            }
        }

        /// IF nothing is selected by the user
        /// What size is under the cursor
        let currentAttrs = textView.typingAttributes
        let font: NSFont = currentAttrs[.font] as? NSFont ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        
        return font.pointSize
    }
}


// MARK: - Bold
extension TextViewDelegate {
    /// Bold information that is returned
    typealias BoldFontInfo = (Bool, [NSAttributedString.Key: Any], NSFont)
    
    /// Public Function to toggle bold
    /// Could be on selection OR entire editor
    ///     Currently set to 1 or the other
    ///     TODO: Maybe have a "Bold on Selection, Configures"
    public func toggleBold(in textView: NSTextView) {
        /// See if TextView is currently selected or not
        /// If A Range is set
        if let range = range {
            guard let storage = textView.textStorage else { return }
            let (isBold, _, currentFont) = isCurrentlyBold(range, in: storage)
            
            let newFont =
            isBold
            ? fontManager.convert(currentFont, toNotHaveTrait: .boldFontMask)
            : fontManager.convert(currentFont, toHaveTrait: .boldFontMask)
            
            storage.addAttribute(.font, value: newFont, range: range)
            
            calculateRange(textView)
            /// false because we did not "set" bold
            return
        }
        else {
            let (isBold, currentAttrs, currentFont) = isCurrentlyBold(in: textView)
            let newFont =
            isBold
            ? fontManager.convert(currentFont, toNotHaveTrait: .boldFontMask)
            : fontManager.convert(currentFont, toHaveTrait: .boldFontMask)
            
            var newAttrs = currentAttrs
            newAttrs[.font] = newFont
            textView.typingAttributes = newAttrs
            
            calculateRange(textView)
            return
        }
    }
    

    /// Internal function to get if is bold under a range
    internal func isCurrentlyBold(_ range: NSRange, in storage: NSTextStorage) -> BoldFontInfo {
        let attrs = storage.attributes(at: range.location, effectiveRange: nil)
        let currentFont =
        attrs[.font] as? NSFont ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return (fontManager.traits(of: currentFont).contains(.boldFontMask), attrs, currentFont)
    }
    
    /// Internal function to get if is bold in general
    /// Returns `(Bool, [NSAttributedString.Key : Any], NSFont)`
    internal func isCurrentlyBold(in textView: NSTextView) -> BoldFontInfo {
        let currentAttrs = textView.typingAttributes
        let currentFont =
        currentAttrs[.font] as? NSFont ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return (
            fontManager.traits(of: currentFont).contains(.boldFontMask), currentAttrs, currentFont
        )
    }
    
    /// Public function to get if is bold `no information`
    internal func isCurrentlyBold(in textView: NSTextView) -> Bool {
        let currentAttrs = textView.typingAttributes
        let currentFont =
        currentAttrs[.font] as? NSFont ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return fontManager.traits(of: currentFont).contains(.boldFontMask)
    }
}
