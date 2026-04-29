//
//  FinderSync.swift
//  RightMenuFinderExtension
//
//  Created by Reom Nagasaka on 2026/04/29.
//

import AppKit
import FinderSync

final class FinderSync: FIFinderSync {
    private enum Action: String {
        case newTextFile
        case newMarkdownFile
        case newJSONFile
        case newSwiftFile
        case newHTMLFile
        case newCSSFile
        case newJavaScriptFile
        case newShellScript
        case newFolder
        case duplicateHere
        case copyPath
        case openTerminal
    }

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [FileManager.default.homeDirectoryForCurrentUser]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu(title: "The Right Menu")

        addNewFileMenu(to: menu)
        menu.addItem(.separator())
        addItem("New Folder", symbolName: "folder.badge.plus", action: .newFolder, to: menu)
        menu.addItem(.separator())
        addItem("Duplicate Here", symbolName: "doc.on.doc", action: .duplicateHere, to: menu)
        addItem("Copy Path", symbolName: "link", action: .copyPath, to: menu)
        addItem("Open Terminal Here", symbolName: "terminal", action: .openTerminal, to: menu)

        return menu
    }

    private func addNewFileMenu(to menu: NSMenu) {
        let item = NSMenuItem(title: "New File", action: nil, keyEquivalent: "")
        item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: "New File")

        let submenu = NSMenu(title: "New File")
        addItem("Plain Text", symbolName: "doc.text", action: .newTextFile, to: submenu)
        addItem("Markdown", symbolName: "text.alignleft", action: .newMarkdownFile, to: submenu)
        addItem("JSON", symbolName: "curlybraces", action: .newJSONFile, to: submenu)
        addItem("Swift", symbolName: "swift", action: .newSwiftFile, to: submenu)
        addItem("HTML", symbolName: "chevron.left.forwardslash.chevron.right", action: .newHTMLFile, to: submenu)
        addItem("CSS", symbolName: "paintbrush", action: .newCSSFile, to: submenu)
        addItem("JavaScript", symbolName: "curlybraces.square", action: .newJavaScriptFile, to: submenu)
        addItem("Shell Script", symbolName: "terminal", action: .newShellScript, to: submenu)

        menu.setSubmenu(submenu, for: item)
        menu.addItem(item)
    }

    private func addItem(_ title: String, symbolName: String, action: Action, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(runMenuAction(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = action.rawValue
        item.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)
        menu.addItem(item)
    }

    @objc private func runMenuAction(_ sender: NSMenuItem) {
        guard
            let rawAction = sender.representedObject as? String,
            let action = Action(rawValue: rawAction)
        else {
            return
        }

        switch action {
        case .newTextFile:
            createFile(named: "Untitled.txt", contents: "")
        case .newMarkdownFile:
            createFile(named: "Untitled.md", contents: "# Untitled\n")
        case .newJSONFile:
            createFile(named: "Untitled.json", contents: "{\n  \n}\n")
        case .newSwiftFile:
            createFile(named: "Untitled.swift", contents: "import Foundation\n\n")
        case .newHTMLFile:
            createFile(named: "Untitled.html", contents: "<!doctype html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\">\n  <title>Untitled</title>\n</head>\n<body>\n\n</body>\n</html>\n")
        case .newCSSFile:
            createFile(named: "Untitled.css", contents: ":root {\n  color-scheme: light dark;\n}\n\n")
        case .newJavaScriptFile:
            createFile(named: "Untitled.js", contents: "\"use strict\";\n\n")
        case .newShellScript:
            createFile(named: "Untitled.sh", contents: "#!/bin/zsh\n\n", makeExecutable: true)
        case .newFolder:
            createFolder(named: "New Folder")
        case .duplicateHere:
            duplicateSelectedItems()
        case .copyPath:
            copySelectedPaths()
        case .openTerminal:
            openTerminal()
        }
    }

    private func createFile(named filename: String, contents: String, makeExecutable: Bool = false) {
        guard let destination = actionDirectory() else {
            return
        }

        let fileURL = uniqueURL(in: destination, preferredName: filename)

        do {
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)

            if makeExecutable {
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fileURL.path)
            }

            reveal([fileURL])
        } catch {
            showError(error)
        }
    }

    private func createFolder(named folderName: String) {
        guard let destination = actionDirectory() else {
            return
        }

        let folderURL = uniqueURL(in: destination, preferredName: folderName)

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            reveal([folderURL])
        } catch {
            showError(error)
        }
    }

    private func duplicateSelectedItems() {
        let selectedURLs = selectedItemURLs()

        guard !selectedURLs.isEmpty else {
            return
        }

        var duplicatedURLs: [URL] = []

        do {
            for sourceURL in selectedURLs {
                let duplicateURL = uniqueDuplicateURL(for: sourceURL)
                try FileManager.default.copyItem(at: sourceURL, to: duplicateURL)
                duplicatedURLs.append(duplicateURL)
            }

            reveal(duplicatedURLs)
        } catch {
            showError(error)
        }
    }

    private func copySelectedPaths() {
        let urls = selectedItemURLs()
        let paths = urls.isEmpty ? actionDirectory().map { [$0.path] } ?? [] : urls.map(\.path)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths.joined(separator: "\n"), forType: .string)
    }

    private func openTerminal() {
        guard let directory = actionDirectory() else {
            return
        }

        NSWorkspace.shared.open([directory], withApplicationAt: terminalURL(), configuration: NSWorkspace.OpenConfiguration())
    }

    private func selectedItemURLs() -> [URL] {
        FIFinderSyncController.default().selectedItemURLs() ?? []
    }

    private func actionDirectory() -> URL? {
        if let selectedURL = selectedItemURLs().first {
            if isDirectory(selectedURL) {
                return selectedURL
            }

            return selectedURL.deletingLastPathComponent()
        }

        return FIFinderSyncController.default().targetedURL()
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }

    private func uniqueURL(in directory: URL, preferredName: String) -> URL {
        let preferredURL = directory.appendingPathComponent(preferredName)

        if !FileManager.default.fileExists(atPath: preferredURL.path) {
            return preferredURL
        }

        let baseName = preferredURL.deletingPathExtension().lastPathComponent
        let pathExtension = preferredURL.pathExtension

        for index in 2...999 {
            let candidateName: String

            if pathExtension.isEmpty {
                candidateName = "\(baseName) \(index)"
            } else {
                candidateName = "\(baseName) \(index).\(pathExtension)"
            }

            let candidateURL = directory.appendingPathComponent(candidateName)

            if !FileManager.default.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
        }

        return directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(pathExtension)
    }

    private func uniqueDuplicateURL(for sourceURL: URL) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let pathExtension = sourceURL.pathExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let copyName = pathExtension.isEmpty ? "\(baseName) copy" : "\(baseName) copy.\(pathExtension)"

        return uniqueURL(in: directory, preferredName: copyName)
    }

    private func reveal(_ urls: [URL]) {
        guard !urls.isEmpty else {
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    private func terminalURL() -> URL {
        URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
    }

    private func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "The Right Menu could not complete the action."
        alert.runModal()
    }
}
