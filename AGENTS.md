# Agent Instructions

This repository contains **The Right Menu**, a macOS SwiftUI app plus an embedded Finder Sync extension. Treat the app and extension as one product. The public release artifact must be the signed, notarized app bundle containing the extension, not a standalone extension.

## Operating Stance

- Be direct, neutral, and evidence-driven.
- Challenge weak assumptions, especially around what macOS allows Finder extensions to do.
- Do not pretend Finder supports UI affordances it does not support.
- Prefer small, working changes over speculative architecture.
- Preserve user changes. Never reset or revert unrelated work without explicit permission.

## Platform Reality

macOS does not allow third-party apps to add a literal new column to Finder's native right-click menu. The supported integration is a Finder Sync extension that contributes context menu items. Keep the UX language honest: this project adds **The Right Menu** as a Finder context menu item/submenu.

## Project Layout

- `theRightMenu/` is the main SwiftUI macOS app.
- `RightMenuFinderExtension/` is the Finder Sync extension.
- `RightMenuFinderExtension/FinderSync.swift` owns Finder menu items and file actions.
- `theRightMenu/ContentView.swift` owns the companion app UI and setup controls.
- `theRightMenu.xcodeproj/project.pbxproj` contains the app target, extension target, embedding, signing, and build settings.

## Build Commands

Use this as the baseline local build:

```sh
xcodebuild -project theRightMenu.xcodeproj -scheme theRightMenu -configuration Debug build
```

For release validation, use a Release build or archive flow rather than assuming Debug behavior is enough.

## Finder Extension Debugging

Useful checks:

```sh
pluginkit -m -A -D -v -p com.apple.FinderSync | rg -C 2 -i "RightMenu|theRightMenu|com.reom"
pluginkit -e use -i com.reom.theRightMenu.FinderExtension
killall Finder
```

If Finder does not show the menu, verify:

- The extension is embedded inside `theRightMenu.app/Contents/PlugIns/`.
- The extension is sandboxed.
- The extension appears in PlugInKit.
- The extension is enabled in System Settings.
- Finder has been relaunched after enabling.

## Release Expectations

The GitHub Actions release workflow should eventually produce a public macOS app release. It should:

1. Build the app and embedded extension.
2. Sign with the correct Developer ID Application certificate.
3. Enable hardened runtime where required.
4. Archive and export the app.
5. Notarize with Apple.
6. Staple the notarization ticket.
7. Package as `.dmg` or `.zip`.
8. Upload the package to a GitHub Release.

Do not commit signing assets or secrets. Use GitHub Actions secrets for certificates, passwords, keychain credentials, Apple API keys, and notarization credentials.

## Coding Guidelines

- Follow existing Swift and SwiftUI style.
- Keep Finder actions in `FinderSync.swift` unless there is a clear reason to extract shared logic.
- Avoid broad filesystem permissions unless the Finder Sync use case truly requires them.
- Add user-visible errors for failed file operations.
- Keep menu actions predictable and reversible where possible.
- When adding new file templates, use unique filenames and safe defaults.
- Do not add marketing-page UI to the app. The app is a utility/control surface.

## Documentation Guidelines

- Keep `README.md` accurate about Apple platform limits.
- Document setup and release steps that a real user or maintainer can execute.
- Do not claim public release readiness until signing, notarization, packaging, and update/release flow have been verified.
