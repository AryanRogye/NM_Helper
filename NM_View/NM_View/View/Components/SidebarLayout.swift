//
//  SidebarLayout.swift
//  NM_View
//
//  Fixed sidebar layout with a non-collapsible minimum width.
//

import SwiftUI
import AppKit

struct SidebarLayout<Sidebar: View, Content: View>: View {
    let isSidebarVisible: Bool
    let minSidebarWidth: CGFloat
    let maxSidebarWidth: CGFloat?
    let sidebar: Sidebar
    let content: Content
    
    @State private var sidebarWidth: CGFloat
    @GestureState private var dragDelta: CGFloat = 0

    init(
        isSidebarVisible: Bool = true,
        minSidebarWidth: CGFloat = 220,
        maxSidebarWidth: CGFloat? = nil,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) {
        self.isSidebarVisible = isSidebarVisible
        self.minSidebarWidth = minSidebarWidth
        self.maxSidebarWidth = maxSidebarWidth
        self.sidebar = sidebar()
        self.content = content()
        _sidebarWidth = State(initialValue: minSidebarWidth)
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            HStack(spacing: 0) {
                sidebar
                    .frame(width: sidebarWidthForVisibility)
                    .opacity(isSidebarVisible ? 1 : 0)
                    .allowsHitTesting(isSidebarVisible)

                ResizableDivider()
                    .frame(width: isSidebarVisible ? 10 : 0)
                    .opacity(isSidebarVisible ? 1 : 0)
                    .allowsHitTesting(isSidebarVisible)
                    .gesture(resizeGesture)
                
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var clampedSidebarWidth: CGFloat {
        clamp(sidebarWidth + dragDelta)
    }

    private var sidebarWidthForVisibility: CGFloat {
        isSidebarVisible ? clampedSidebarWidth : 0
    }

    private var resizeGesture: some Gesture {
        DragGesture()
            .updating($dragDelta) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let next = sidebarWidth + value.translation.width
                sidebarWidth = clamp(next)
            }
    }
    
    private func clamp(_ value: CGFloat) -> CGFloat {
        let upper = maxSidebarWidth ?? .infinity
        return min(max(value, minSidebarWidth), upper)
    }
}

private struct ResizableDivider: NSViewRepresentable {
    func makeNSView(context: Context) -> DividerHandleView {
        DividerHandleView()
    }

    func updateNSView(_ nsView: DividerHandleView, context: Context) {}
}

private final class DividerHandleView: NSView {
    private var trackingAreaRef: NSTrackingArea?
    private var isHovering = false {
        didSet { needsDisplay = true }
    }

    override var mouseDownCanMoveWindow: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)
        trackingAreaRef = tracking
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsDisplay = true
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        NSCursor.resizeLeftRight.push()
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        NSCursor.pop()
    }

    override func draw(_ dirtyRect: NSRect) {
        let bg = isHovering
            ? NSColor.labelColor.withAlphaComponent(0.08)
            : NSColor.clear
        bg.setFill()
        dirtyRect.fill()

        let lineX = bounds.midX - 0.5
        let lineRect = NSRect(x: lineX, y: 0, width: 1, height: bounds.height)
        NSColor.separatorColor.setFill()
        lineRect.fill()
    }
}
