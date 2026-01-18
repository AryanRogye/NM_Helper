//
//  ComfyTextView+Vim+InsertionPoint.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/6/25.
//

import AppKit

extension ComfyTextView {
    
    func updateVimCursor(with rect: NSRect) {
        // Safety check: Don't show cursor if rect is nonsense
        guard !rect.isEmpty else {
            vimCursorView.isHidden = true
            return
        }
        
        vimCursorView.isHidden = false
        
        // Optional: Use a very fast animation (0.05s) to make it feel fluid like VS Code
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.05
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            vimCursorView.animator().frame = rect
        }, completionHandler: nil)
    }
    
    func handleVimInsertionPoint(_ rect: NSRect, _ color: NSColor) {
        var blockRect = rect
        
        if let layoutManager = layoutManager, let textContainer = textContainer, !vimEngine.isOnNewLine, vimEngine.state != .insert {
            
            
            let range = self.selectedRange()
            
            /// Get location of the index of the character
            let logicalIndex: Int
            
            if range.length == 0 {
                logicalIndex = range.location
            } else {
                logicalIndex = NSMaxRange(range) - 1
            }
            
            let endOfDocument = self.textStorage?.length ?? 0
            
            if logicalIndex < endOfDocument {
                
                // Ask LayoutManager where this SPECIFIC character is
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: logicalIndex)
                var glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)
                
                // (Without this, the block will be stuck in the wrong place)
                glyphRect.origin.x += textContainerOrigin.x
                glyphRect.origin.y += textContainerOrigin.y
                
                // 3. Update the drawing rect to match this character exactly
                blockRect = glyphRect
                
                // Fallback for newlines (which have 0 width)
                if glyphRect.width <= 1 {
                    blockRect.size.width = font?.pointSize ?? 12
                }
            }
            else {
                // End of document; use the width of 'm'
                if let font = self.font {
                    blockRect.size.width = "m".size(withAttributes: [.font: font]).width
                }
            }
        }
        else if vimEngine.state == .insert {
            blockRect.size.width = 1
        }
        else {
            if let font = self.font {
                blockRect.size.width = "m".size(withAttributes: [.font: font]).width
            }
        }
        
        updateVimCursor(with: blockRect)
    }
}
