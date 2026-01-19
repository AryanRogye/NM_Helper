//
//  WorkspaceEmptyStateView.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/19/26.
//

import AppKit
import SwiftUI
import nmcore

struct WorkspaceEmptyStateView: View {
    let workspace: Workspace
    @Binding var currentFlags: [NMFlags]
    let onLoad: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("No data loaded")
                    .font(.headline)
                Text(workspace.file.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .truncationMode(.middle)
            }

            VStack(spacing: 12) {
                EmptyStateConfigurationView(currentFlags: $currentFlags)
                    .id(workspace.file)

                Spacer(minLength: 12)

                HStack {
                    Text(nmCommand)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 12) {
                    bottomActionsView
                    Spacer()
                    Button(action: onLoad) {
                        Label("Load nm output", systemImage: "arrow.down.doc")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.secondary.opacity(0.1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

// MARK: - Command
extension WorkspaceEmptyStateView {
    private var nmCommand: String {
        var output: String = "nm"
        for flag in currentFlags {
            output += " \(flag.flag)"
        }
        output += " \(workspace.file.path)"
        return output
    }
}

// MARK: - Actions
extension WorkspaceEmptyStateView {
    private var bottomActionsView: some View {
        HStack(spacing: 8) {
            Button {
                revealInFinder()
            } label: {
                Label("Reveal in Finder", systemImage: "folder")
            }

            Button {
                copyPath()
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }

            Button {
                openInTerminal()
            } label: {
                Label("Open in Terminal", systemImage: "terminal")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([workspace.file])
    }

    private func copyPath() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(workspace.file.path, forType: .string)
    }

    private func openInTerminal() {
        let folder = workspace.file.deletingLastPathComponent()
        let terminalURL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([folder], withApplicationAt: terminalURL, configuration: config)
    }
}

private struct EmptyStateConfigurationView: View {
    @State private var showOnlyExternalSymbols = false
    @State private var hideUndefinedSymbols = false
    @State private var showUndefinedSymbols = false

    @State private var sortByAddress = false
    @State private var dontSort = false

    @State private var justSymbolNames = false
    @State private var includeDebugSymbols = false
    @State private var reverse = false

    @Binding private var currentFlags: [NMFlags]

    init(currentFlags: Binding<[NMFlags]>) {
        self._currentFlags = currentFlags
    }

    struct DisabledModifier: ViewModifier {
        let disabled: Bool

        func body(content: Content) -> some View {
            content
                .opacity(disabled ? 0.5 : 1)
                .animation(.easeInOut, value: disabled)
        }
    }

    var body: some View {
        List {
            Section("Symbols") {
                SectionRow(
                    label: "Show External Symbols Only",
                    isOn: $showOnlyExternalSymbols,
                    disabled: showUndefinedSymbols
                )

                SectionRow(
                    label: "Hide Undefined Symbols",
                    isOn: $hideUndefinedSymbols,
                    disabled: showUndefinedSymbols
                )
                SectionRow(
                    label: "Show Undefined Symbols Only",
                    isOn: $showUndefinedSymbols,
                    disabled: self.hideUndefinedSymbols || self.showOnlyExternalSymbols
                )
            }

            Section("Sorting") {
                SectionRow(
                    label: "Sort By Address",
                    isOn: $sortByAddress,
                    disabled: dontSort
                )
                SectionRow(
                    label: "Dont Sort",
                    isOn: $dontSort,
                    disabled: sortByAddress
                )
            }

            Section {
                SectionRow(
                    label: "Reverse Output",
                    isOn: $reverse,
                    disabled: false
                )
                SectionRow(
                    label: "Just Symbol Names",
                    isOn: $justSymbolNames,
                    disabled: false
                )
                SectionRow(
                    label: "Include Debug Symbols",
                    isOn: $includeDebugSymbols,
                    disabled: false
                )
            } footer: {
                if showOnlyExternalSymbols && includeDebugSymbols {
                    Text("⚠️ Include Debug Symbols is mostly useless when only showing external symbols.")
                        .foregroundStyle(.secondary)
                }
            }
            .animation(.spring, value: showOnlyExternalSymbols)
            .animation(.spring, value: includeDebugSymbols)
        }
        .listStyle(.bordered)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: [
            showOnlyExternalSymbols,
            hideUndefinedSymbols,
            showUndefinedSymbols,
            sortByAddress,
            dontSort,
            justSymbolNames,
            includeDebugSymbols,
            reverse
        ]) {
            currentFlags = []
            if showOnlyExternalSymbols {
                currentFlags.append(NMFlags.external_symbols)
            }
            if hideUndefinedSymbols {
                currentFlags.append(NMFlags.hide_undefined_symbols)
            }
            if showUndefinedSymbols {
                currentFlags.append(NMFlags.only_undefined_symbols)
            }
            if sortByAddress {
                currentFlags.append(NMFlags.sort_by_address)
            }
            if dontSort {
                currentFlags.append(NMFlags.no_sorting)
            }
            if justSymbolNames {
                currentFlags.append(NMFlags.just_symbol_names)
            }
            if includeDebugSymbols {
                currentFlags.append(NMFlags.include_debug_symbols)
            }
            if reverse {
                currentFlags.append(NMFlags.reverse_sort)
            }
        }
    }

    private struct SectionRow: View {
        let label: String
        @Binding var isOn: Bool
        let disabled: Bool

        var body: some View {
            HStack {
                Text(label)
                    .modifier(DisabledModifier(disabled: disabled))
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(disabled)
            }
        }
    }
}
