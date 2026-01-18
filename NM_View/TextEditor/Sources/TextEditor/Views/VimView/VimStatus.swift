//
//  VimStatus.swift
//  TextEditor
//
//  Created by Aryan Rogye on 12/5/25.
//

import SwiftUI
import Combine

final class VimStatusViewModel: ObservableObject {
    @Published var foregroundStyle: Color
    init(foregroundStyle: Color) {
        self.foregroundStyle = foregroundStyle
    }
}

struct VimStatus: View {
    
    @ObservedObject var vimEngine: VimEngine
    @ObservedObject var vimStatusVM : VimStatusViewModel
    
    /// This is dependent on if vim is enabled or not
    var opacity: CGFloat {
        vimEngine.isInVimMode ? 0.8 : 0
    }
    var shouldShow: Bool {
        vimEngine.isInVimMode
    }
    var opacityBackground: CGFloat {
        vimEngine.isInVimMode ? 0.3 : 0
    }
    var color: Color {
        switch vimEngine.state {
        case .command: .yellow
        case .normal: .gray
        case .insert: .purple
        case .visual: .cyan
        case .visualLine: .cyan
        }
    }
    
    var body: some View {
        HStack {
            if vimEngine.state == .command {
                Text(vimEngine.commandBuffer)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(vimStatusVM.foregroundStyle)
                    .opacity(opacity)
                    .padding(.vertical, 2)
            } else {
                Text(vimEngine.state.displayName)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(vimStatusVM.foregroundStyle)
                    .opacity(opacity)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(opacityBackground))
                    }
            }
            
            Spacer()
            
            Text("Line: \(vimEngine.position.map { String($0.line) } ?? "_")  Col: \(vimEngine.position.map { String($0.column) } ?? "_")")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(vimStatusVM.foregroundStyle)
                .opacity(opacity)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    @Previewable @StateObject var vimEngine1 = VimEngine()
    @Previewable @StateObject var vimEngine2 = VimEngine()
    @Previewable @StateObject var vimEngine3 = VimEngine()
    @Previewable @StateObject var vimEngine4 = VimEngine()
    
    let test: (VimEngine) -> some View = { engine in
        HStack {
            VimStatus(
                vimEngine: engine,
                vimStatusVM: VimStatusViewModel(
                    foregroundStyle: .white,
                    
                )
            )
            Spacer()
        }
        .border(Color.black)
    }
    
    VStack {
        VStack(spacing: 8) {
            test(vimEngine1)
                .task {
                    vimEngine1.isInVimMode = false
                }
            test(vimEngine2)
                .task {
                    vimEngine2.isInVimMode = true
                    vimEngine2.state = .normal
                }
            test(vimEngine3)
                .task {
                    vimEngine3.isInVimMode = true
                    vimEngine3.state = .insert
                }
            test(vimEngine4)
                .task {
                    vimEngine4.isInVimMode = true
                    vimEngine4.state = .visual
                }
        }
        .frame(width: 100, height: 120)
    }
}
