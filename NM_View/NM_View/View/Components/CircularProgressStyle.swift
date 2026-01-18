//
//  CircularProgressStyle.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/18/26.
//

import SwiftUI

struct CircularProgressStyle: ProgressViewStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        if let label = configuration.label {
            HStack(spacing: 0) {
                label
                    .padding(.leading, 4)
                Spacer()
                circles(configuration: configuration)
            }
        } else {
            circles(configuration: configuration)
        }
    }
    
    @ViewBuilder
    private func circles(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 6)
                .opacity(0.2)
            
            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeInOut, value: configuration.fractionCompleted)
    }
}
