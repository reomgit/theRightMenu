//
//  FinderSync.swift
//  RightMenuFinderExtension
//
//  Created by Reom Nagasaka on 2026/04/29.
//

import AppKit
import FinderSync

final class FinderSync: FIFinderSync {
    private enum RightMenuError: LocalizedError {
        case missingDestination
        case couldNotCreateFile(URL)
        case invalidFilename

        var errorDescription: String? {
            switch self {
            case .missingDestination:
                "Finder did not provide a target folder for this action."
            case .couldNotCreateFile(let url):
                "Could not create \(url.lastPathComponent)."
            case .invalidFilename:
                "The filename is not valid."
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .missingDestination:
                "Right-click a Finder folder, a file, or an empty area inside a Finder window and try again."
            case .couldNotCreateFile(let url):
                "Check whether The Right Menu has permission to write to \(url.deletingLastPathComponent().path)."
            case .invalidFilename:
                "Use a filename that is not empty and does not contain slashes."
            }
        }
    }

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        NSLog("The Right Menu Finder extension initialized")
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        NSLog("The Right Menu building Finder menu for kind \(menuKind.rawValue)")

        let menu = NSMenu(title: "")
        let rootItem = NSMenuItem(title: "The Right Menu", action: nil, keyEquivalent: "")
        rootItem.image = NSImage(systemSymbolName: "contextualmenu.and.cursorarrow", accessibilityDescription: "The Right Menu")

        let submenu = NSMenu(title: "The Right Menu")
        addNewFileMenu(to: submenu)
        submenu.addItem(.separator())
        addItem("Duplicate Here", symbolName: "doc.on.doc", action: #selector(duplicateHere(_:)), to: submenu)
        addItem("Copy Path", symbolName: "link", action: #selector(copyPath(_:)), to: submenu)
        addItem("Open Terminal Here", symbolName: "terminal", action: #selector(openTerminalHere(_:)), to: submenu)

        menu.setSubmenu(submenu, for: rootItem)
        menu.addItem(rootItem)
        return menu
    }

    private func addNewFileMenu(to menu: NSMenu) {
        let item = NSMenuItem(title: "New File", action: nil, keyEquivalent: "")
        item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: "New File")

        let submenu = NSMenu(title: "New File")
        addItem("Plain Text", symbolName: "doc.text", action: #selector(createPlainTextFile(_:)), to: submenu)
        addItem("Markdown", symbolName: "text.alignleft", action: #selector(createMarkdownFile(_:)), to: submenu)
        addItem("JSON", symbolName: "curlybraces", action: #selector(createJSONFile(_:)), to: submenu)
        addItem("Swift", symbolName: "swift", action: #selector(createSwiftFile(_:)), to: submenu)
        addItem("HTML", symbolName: "chevron.left.forwardslash.chevron.right", action: #selector(createHTMLFile(_:)), to: submenu)
        addItem("CSS", symbolName: "paintbrush", action: #selector(createCSSFile(_:)), to: submenu)
        addItem("JavaScript", symbolName: "curlybraces.square", action: #selector(createJavaScriptFile(_:)), to: submenu)
        addItem("Shell Script", symbolName: "terminal", action: #selector(createShellScript(_:)), to: submenu)

        menu.setSubmenu(submenu, for: item)
        menu.addItem(item)
    }

    private func addItem(_ title: String, symbolName: String, action: Selector, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: title)
        menu.addItem(item)
    }

    @objc func createPlainTextFile(_ sender: Any?) {
        createFile(named: "Untitled.txt", contents: "")
    }

    @objc func createMarkdownFile(_ sender: Any?) {
        createFile(named: "Untitled.md", contents: "# Untitled\n")
    }

    @objc func createJSONFile(_ sender: Any?) {
        createFile(named: "Untitled.json", contents: "{\n  \n}\n")
    }

    @objc func createSwiftFile(_ sender: Any?) {
        createFile(named: "Untitled.swift", contents: "import Foundation\n\n")
    }

    @objc func createHTMLFile(_ sender: Any?) {
        createFile(named: "Untitled.html", contents: "<!doctype html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\">\n  <title>Untitled</title>\n</head>\n<body>\n\n</body>\n</html>\n")
    }

    @objc func createCSSFile(_ sender: Any?) {
        createFile(named: "Untitled.css", contents: ":root {\n  color-scheme: light dark;\n}\n\n")
    }

    @objc func createJavaScriptFile(_ sender: Any?) {
        createFile(named: "Untitled.js", contents: "\"use strict\";\n\n")
    }

    @objc func createShellScript(_ sender: Any?) {
        createFile(named: "Untitled.sh", contents: "#!/bin/zsh\n\n", makeExecutable: true)
    }

    @objc func duplicateHere(_ sender: Any?) {
        duplicateSelectedItems()
    }

    @objc func copyPath(_ sender: Any?) {
        copySelectedPaths()
    }

    @objc func openTerminalHere(_ sender: Any?) {
        openTerminal()
    }

    private func createFile(named filename: String, contents: String, makeExecutable: Bool = false) {
        NSLog("The Right Menu creating file \(filename)")

        guard let destination = actionDirectory() else {
            showError(RightMenuError.missingDestination)
            return
        }

        guard let chosenFilename = promptForFilename(defaultFilename: filename) else {
            return
        }

        let fileURL = uniqueURL(in: destination, preferredName: chosenFilename)

        do {
            try withScopedAccess(to: destination) {
                guard FileManager.default.createFile(
                    atPath: fileURL.path,
                    contents: contents.data(using: .utf8),
                    attributes: makeExecutable ? [.posixPermissions: 0o755] : nil
                ) else {
                    throw RightMenuError.couldNotCreateFile(fileURL)
                }
            }

            reveal([fileURL])
        } catch {
            showError(error)
        }
    }

    private func duplicateSelectedItems() {
        NSLog("The Right Menu duplicating selected items")

        let selectedURLs = selectedItemURLs()

        guard !selectedURLs.isEmpty else {
            return
        }

        var duplicatedURLs: [URL] = []

        do {
            for sourceURL in selectedURLs {
                let duplicateURL = uniqueDuplicateURL(for: sourceURL)
                try withScopedAccess(to: sourceURL) {
                    try withScopedAccess(to: duplicateURL.deletingLastPathComponent()) {
                        try FileManager.default.copyItem(at: sourceURL, to: duplicateURL)
                    }
                }
                duplicatedURLs.append(duplicateURL)
            }

            reveal(duplicatedURLs)
        } catch {
            showError(error)
        }
    }

    private func copySelectedPaths() {
        NSLog("The Right Menu copying paths")

        let urls = selectedItemURLs()
        let paths = urls.isEmpty ? actionDirectory().map { [$0.path] } ?? [] : urls.map(\.path)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths.joined(separator: "\n"), forType: .string)
    }

    private func openTerminal() {
        NSLog("The Right Menu opening Terminal")

        guard let directory = actionDirectory() else {
            showError(RightMenuError.missingDestination)
            return
        }

        NSWorkspace.shared.open([directory], withApplicationAt: terminalURL(), configuration: NSWorkspace.OpenConfiguration())
    }

    private func selectedItemURLs() -> [URL] {
        FIFinderSyncController.default().selectedItemURLs() ?? []
    }

    private func actionDirectory() -> URL? {
        if let selectedURL = selectedItemURLs().first {
            NSLog("The Right Menu selected URL: \(selectedURL.path)")

            if isDirectory(selectedURL) {
                return selectedURL
            }

            return selectedURL.deletingLastPathComponent()
        }

        let targetedURL = FIFinderSyncController.default().targetedURL()
        NSLog("The Right Menu targeted URL: \(targetedURL?.path ?? "nil")")
        return targetedURL
    }

    private func promptForFilename(defaultFilename: String) -> String? {
        let alert = NSAlert()
        alert.messageText = "Name the new file"
        alert.informativeText = "The file will be created after you confirm the name."
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        textField.stringValue = defaultFilename
        textField.selectText(nil)
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        do {
            return try normalizedFilename(textField.stringValue, defaultFilename: defaultFilename)
        } catch {
            showError(error)
            return nil
        }
    }

    private func normalizedFilename(_ filename: String, defaultFilename: String) throws -> String {
        let trimmedFilename = filename.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFilename.isEmpty, !trimmedFilename.contains("/") else {
            throw RightMenuError.invalidFilename
        }

        let defaultExtension = URL(fileURLWithPath: defaultFilename).pathExtension
        let chosenExtension = URL(fileURLWithPath: trimmedFilename).pathExtension

        if chosenExtension.isEmpty, !defaultExtension.isEmpty {
            return "\(trimmedFilename).\(defaultExtension)"
        }

        return trimmedFilename
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

    private func withScopedAccess<T>(to url: URL, operation: () throws -> T) throws -> T {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }

    private func terminalURL() -> URL {
        URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
    }

    private func showError(_ error: Error) {
        NSLog("The Right Menu Finder action failed: \(error.localizedDescription)")

        let alert = NSAlert(error: error)
        alert.messageText = "The Right Menu could not complete the action."
        alert.runModal()
    }
}
