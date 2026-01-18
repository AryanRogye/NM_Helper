//
//  VimBottomView.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/5/25.
//

import AppKit
import SwiftUI
import Combine

final class VimBottomView: NSView {
    
    var vimEngine : VimEngine
    
    private let topBorder = CALayer()
    private var borderThickness: CGFloat = 1
    
    var foregroundStyle: Color
    lazy var vimStatusVM = VimStatusViewModel(foregroundStyle: foregroundStyle)
    
    lazy var vimStatusView = VimStatus(
        vimEngine: vimEngine,
        vimStatusVM: vimStatusVM
    )

    init(
        vimEngine: VimEngine,
        foregroundStyle: Color
    ) {
        self.vimEngine = vimEngine
        self.foregroundStyle = foregroundStyle
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        setup()
    }
    
    override func layout() {
        super.layout()
        topBorder.frame = CGRect(
            x: 0,
            y: bounds.height - borderThickness,
            width: bounds.width,
            height: borderThickness
        )
    }
    
    public func setForegroundStyle(color: Color) {
        DispatchQueue.main.async {
            self.vimStatusVM.foregroundStyle = color
        }
    }
    
    public func setBorderColor(color: NSColor) {
        wantsLayer = true
        topBorder.backgroundColor = color.cgColor
        needsLayout = true
    }
    
    public func setBackground(color: NSColor) {
        layer?.backgroundColor = color.cgColor
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        let hosting = NSHostingView(rootView: vimStatusView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosting)
        
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hosting.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            hosting.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        layer?.addSublayer(topBorder)
    }
}
