//
//  ContentView.swift
//  theRightMenu
//
//  Created by Reom Nagasaka on 2026/04/29.
//

import AppKit
import SwiftUI

struct ContentView: View {
    private let features = [
        Feature(symbol: "doc.badge.plus", title: "Create files", detail: "Text, Markdown, JSON, Swift, HTML, CSS, JavaScript, and shell scripts."),
        Feature(symbol: "folder.badge.plus", title: "Create folders", detail: "Adds a new folder exactly where you right-click in Finder."),
        Feature(symbol: "doc.on.doc", title: "Duplicate here", detail: "Copies the selected file or folder beside the original with a safe unique name."),
        Feature(symbol: "link", title: "Copy paths", detail: "Copies POSIX paths for selected Finder items to the clipboard."),
        Feature(symbol: "terminal", title: "Open Terminal", detail: "Opens Terminal at the current folder or selected folder.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Finder menu extension")
                    .font(.headline)

                Text("macOS does not allow apps to add a literal second column to Finder's native right-click menu. The supported version is a Finder Sync extension that adds a submenu named The Right Menu.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                ForEach(features) { feature in
                    GridRow {
                        Image(systemName: feature.symbol)
                            .font(.title3)
                            .frame(width: 28)
                            .foregroundStyle(.tint)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(feature.title)
                                .font(.subheadline.weight(.semibold))
                            Text(feature.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Enable it")
                    .font(.headline)

                Text("Build and run this app, then enable the Finder extension in System Settings > General > Login Items & Extensions > Finder Extensions. Relaunch Finder if the menu does not appear immediately.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button {
                        openExtensionSettings()
                    } label: {
                        Label("Open Extension Settings", systemImage: "switch.2")
                    }

                    Button {
                        relaunchFinder()
                    } label: {
                        Label("Relaunch Finder", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .padding(28)
        .frame(width: 620, alignment: .leading)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "contextualmenu.and.cursorarrow")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 5) {
                Text("The Right Menu")
                    .font(.largeTitle.weight(.semibold))
                Text("Everyday Finder actions where people already reach for them.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func openExtensionSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func relaunchFinder() {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").forEach {
            $0.terminate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let configuration = NSWorkspace.OpenConfiguration()
            let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
            NSWorkspace.shared.openApplication(at: finderURL, configuration: configuration)
        }
    }
}

private struct Feature: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let detail: String
}

#Preview {
    ContentView()
}
