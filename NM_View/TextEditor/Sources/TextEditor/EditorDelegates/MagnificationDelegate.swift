//
//  MagnificationDelegate.swift
//  ComfyEditor
//
//  Created by Aryan Rogye on 12/2/25.
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class MagnificationDelegate: NSObject, ScrollViewMagnificationDelegate, ObservableObject {
    
    var magnification: Binding<CGFloat> = .constant(4.0)
    
    public func observeMagnification(_ val: Binding<CGFloat>) {
        self.magnification = val
    }
    
    func scrollView(_ scrollView: NSScrollView, didChangeMagnification magnification: CGFloat) {
        self.magnification.wrappedValue = magnification
    }
}
