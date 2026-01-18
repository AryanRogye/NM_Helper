//
//  ComfyScrollView.swift
//  ComfyEditor
//
//  Created by Aryan Rogye on 12/2/25.
//

import AppKit

final class RedrawClipView: NSClipView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Layer-backing for smoother zoom transitions
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func scroll(to newOrigin: NSPoint) {
        super.scroll(to: newOrigin)
        documentView?.setNeedsDisplay(documentVisibleRect)  // force redraw
    }

    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        let r = super.constrainBoundsRect(proposedBounds)
        documentView?.setNeedsDisplay(r)
        return r
    }
}

final class ComfyScrollView: NSScrollView {
    weak var magnificationDelegate: ScrollViewMagnificationDelegate?

    init() {
        super.init(frame: .zero)

        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay

        hasVerticalScroller = true
        hasHorizontalScroller = true
        autohidesScrollers = true

        hasVerticalRuler = false
        hasHorizontalRuler = false
        rulersVisible = false

        translatesAutoresizingMaskIntoConstraints = false
        allowsMagnification = true
        magnification = 4.0
        minMagnification = 0.5
        maxMagnification = 6.0

        /// Enable background drawing so empty areas show the background color
        drawsBackground = true
        /// Will be set by theme
        backgroundColor = .clear
    }

    /// Sets the background color for the scroll view (shown in over-scroll areas)
    func setScrollBackground(_ color: NSColor) {
        backgroundColor = color
        layer?.backgroundColor = color.cgColor
        contentView.layer?.backgroundColor = color.cgColor
    }

    func setZoom(_ value: CGFloat, centeredAt: NSPoint? = nil) {
        let clamped = max(minMagnification, min(value, maxMagnification))

        let center = NSPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
        super.setMagnification(clamped, centeredAt: centeredAt ?? center)

        magnificationDelegate?.scrollView(self, didChangeMagnification: clamped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func magnify(with event: NSEvent) {
        let pointInView = contentView.convert(event.locationInWindow, from: nil)

        let target = magnification + event.magnification
        setZoom(target, centeredAt: pointInView)
    }

    override func setMagnification(_ magnification: CGFloat, centeredAt point: NSPoint) {
        setZoom(magnification, centeredAt: point)
    }

    override func smartMagnify(with event: NSEvent) {
        super.smartMagnify(with: event)
    }
}
