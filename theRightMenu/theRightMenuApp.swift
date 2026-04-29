//
//  theRightMenuApp.swift
//  theRightMenu
//
//  Created by Reom Nagasaka on 2026/04/29.
//

import AppKit
import SwiftUI

@main
struct theRightMenuApp: App {
    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
        } label: {
            Label("The Right Menu", systemImage: "contextualmenu.and.cursorarrow")
        }
        .menuBarExtraStyle(.menu)

        Window("The Right Menu", id: "controlPanel") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

private struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            showControlPanel()
        } label: {
            Label("Control Panel", systemImage: "slider.horizontal.3")
        }

        Divider()

        Menu {
            ForEach(MenuFileTemplate.allCases) { template in
                Button {
                    MenuBarActions.createFile(from: template)
                } label: {
                    Label(template.menuTitle, systemImage: template.symbolName)
                }
            }
        } label: {
            Label("New File...", systemImage: "doc.badge.plus")
        }

        Button {
            MenuBarActions.createFolder()
        } label: {
            Label("New Folder...", systemImage: "folder.badge.plus")
        }

        Divider()

        Button {
            MenuBarActions.openExtensionSettings()
        } label: {
            Label("Open Finder Extension Settings", systemImage: "switch.2")
        }

        Button {
            MenuBarActions.relaunchFinder()
        } label: {
            Label("Relaunch Finder", systemImage: "arrow.clockwise")
        }

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit The Right Menu", systemImage: "power")
        }
    }

    private func showControlPanel() {
        openWindow(id: "controlPanel")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

private enum MenuFileTemplate: String, CaseIterable, Identifiable {
    case plainText
    case markdown
    case json
    case swift
    case html
    case css
    case javascript
    case shellScript

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .plainText:
            "Plain Text"
        case .markdown:
            "Markdown"
        case .json:
            "JSON"
        case .swift:
            "Swift"
        case .html:
            "HTML"
        case .css:
            "CSS"
        case .javascript:
            "JavaScript"
        case .shellScript:
            "Shell Script"
        }
    }

    var defaultFilename: String {
        switch self {
        case .plainText:
            "Untitled.txt"
        case .markdown:
            "Untitled.md"
        case .json:
            "Untitled.json"
        case .swift:
            "Untitled.swift"
        case .html:
            "Untitled.html"
        case .css:
            "Untitled.css"
        case .javascript:
            "Untitled.js"
        case .shellScript:
            "Untitled.sh"
        }
    }

    var contents: String {
        switch self {
        case .plainText:
            ""
        case .markdown:
            "# Untitled\n"
        case .json:
            "{\n  \n}\n"
        case .swift:
            "import Foundation\n\n"
        case .html:
            "<!doctype html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\">\n  <title>Untitled</title>\n</head>\n<body>\n\n</body>\n</html>\n"
        case .css:
            ":root {\n  color-scheme: light dark;\n}\n\n"
        case .javascript:
            "\"use strict\";\n\n"
        case .shellScript:
            "#!/bin/zsh\n\n"
        }
    }

    var symbolName: String {
        switch self {
        case .plainText:
            "doc.text"
        case .markdown:
            "text.alignleft"
        case .json:
            "curlybraces"
        case .swift:
            "swift"
        case .html:
            "chevron.left.forwardslash.chevron.right"
        case .css:
            "paintbrush"
        case .javascript:
            "curlybraces.square"
        case .shellScript:
            "terminal"
        }
    }

    var makeExecutable: Bool {
        self == .shellScript
    }
}

private enum MenuBarActions {
    static func createFile(from template: MenuFileTemplate) {
        let panel = NSSavePanel()
        panel.title = "Create \(template.menuTitle) File"
        panel.nameFieldStringValue = template.defaultFilename
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }

            do {
                try write(template: template, to: url)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } catch {
                showError(error)
            }
        }
    }

    static func createFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Location"
        panel.message = "Choose where The Right Menu should create the folder."
        panel.prompt = "Create Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.begin { response in
            guard response == .OK, let directory = panel.url else {
                return
            }

            let didStartAccessing = directory.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    directory.stopAccessingSecurityScopedResource()
                }
            }

            let folderURL = uniqueURL(in: directory, preferredName: "New Folder")

            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
                NSWorkspace.shared.activateFileViewerSelecting([folderURL])
            } catch {
                showError(error)
            }
        }
    }

    static func openExtensionSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    static func relaunchFinder() {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").forEach {
            $0.terminate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let configuration = NSWorkspace.OpenConfiguration()
            let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
            NSWorkspace.shared.openApplication(at: finderURL, configuration: configuration)
        }
    }

    private static func write(template: MenuFileTemplate, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        let didStartAccessing = directory.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                directory.stopAccessingSecurityScopedResource()
            }
        }

        try template.contents.write(to: url, atomically: true, encoding: .utf8)

        if template.makeExecutable {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        }
    }

    private static func uniqueURL(in directory: URL, preferredName: String) -> URL {
        let preferredURL = directory.appendingPathComponent(preferredName)

        if !FileManager.default.fileExists(atPath: preferredURL.path) {
            return preferredURL
        }

        let baseName = preferredURL.deletingPathExtension().lastPathComponent
        let pathExtension = preferredURL.pathExtension

        for index in 2...999 {
            let candidateName = pathExtension.isEmpty ? "\(baseName) \(index)" : "\(baseName) \(index).\(pathExtension)"
            let candidateURL = directory.appendingPathComponent(candidateName)

            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
        }

        return directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(pathExtension)
    }

    private static func showError(_ error: Error) {
        NSLog("The Right Menu action failed: \(error.localizedDescription)")

        let alert = NSAlert(error: error)
        alert.messageText = "The Right Menu could not complete the action."
        alert.runModal()
    }
}
