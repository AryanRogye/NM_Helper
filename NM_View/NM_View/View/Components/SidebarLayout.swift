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
            Group {
                if isSidebarVisible {
                    HStack(spacing: 0) {
                        sidebar
                            .frame(width: clampedSidebarWidth)
                        
                        Divider()
                        
                        DragHandle()
                            .gesture(
                                DragGesture()
                                    .updating($dragDelta) { value, state, _ in
                                        state = value.translation.width
                                    }
                                    .onEnded { value in
                                        let next = sidebarWidth + value.translation.width
                                        sidebarWidth = clamp(next)
                                    }
                            )
                        
                        content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    private var clampedSidebarWidth: CGFloat {
        clamp(sidebarWidth + dragDelta)
    }
    
    private func clamp(_ value: CGFloat) -> CGFloat {
        let upper = maxSidebarWidth ?? .infinity
        return min(max(value, minSidebarWidth), upper)
    }
}

private struct DragHandle: View {
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .frame(width: 6)
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}
