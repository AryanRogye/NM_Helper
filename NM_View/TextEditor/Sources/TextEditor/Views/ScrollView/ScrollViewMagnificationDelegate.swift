//
//  ScrollViewMagnificationDelegate.swift
//  ComfyEditor
//
//  Created by Aryan Rogye on 12/2/25.
//

import AppKit

@MainActor
protocol ScrollViewMagnificationDelegate: AnyObject {
    func scrollView(_ scrollView: NSScrollView, didChangeMagnification magnification: CGFloat)
}
