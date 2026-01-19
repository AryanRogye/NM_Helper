//
//  WorkspaceToolbarViews.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/19/26.
//

import AppKit
import SwiftUI

struct WorkspaceSearchFieldView: View {
    @Binding var query: String
    @Binding var isFocused: Bool
    let progress: Double?
    let onQueryChange: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            ZStack(alignment: .trailing) {
                FocusableSearchField(
                    text: $query,
                    isFocused: $isFocused,
                    placeholder: "Search"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, progress == nil ? 0 : 52)
                if let progress {
                    searchProgressView(progress: progress)
                        .padding(.trailing, 2)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(width: 220)
        .onChange(of: query) { _, newValue in
            onQueryChange(newValue)
        }
    }

    private func searchProgressView(progress: Double) -> some View {
        HStack(spacing: 4) {
            Text(progress, format: .percent.precision(.fractionLength(0)))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .fixedSize()

            ProgressView(value: progress)
                .progressViewStyle(CircularProgressStyle())
                .frame(width: 16, height: 16)
                .opacity(0.9)
        }
    }
}

private struct FocusableSearchField: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FocusableSearchField

        init(_ parent: FocusableSearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            if field.stringValue != parent.text {
                parent.text = field.stringValue
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            parent.isFocused = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.delegate = context.coordinator
        field.placeholderString = placeholder
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        guard isFocused, nsView.window?.firstResponder !== nsView else { return }
        DispatchQueue.main.async { [weak nsView] in
            guard let nsView else { return }
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

struct WorkspaceProgressToolbarView: View {
    let selectedSize: Int
    let selectedMaxSize: Int

    var body: some View {
        ProgressView(value: CGFloat(selectedSize), total: CGFloat(selectedMaxSize)) {
            let percent = (Double(selectedSize) / Double(selectedMaxSize)) * 100
            Text("\(Int(percent))%")
        }
        .progressViewStyle(CircularProgressStyle())
        .frame(width: 60, height: 18)
    }
}
