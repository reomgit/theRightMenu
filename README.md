# The Right Menu

The Right Menu is a macOS menu bar utility with a Finder Sync extension that adds everyday file actions to Finder's right-click menu.

The important limitation: macOS does not let third-party apps add a literal new column to Finder's native context menu. The supported Apple API is a Finder Sync extension. This project uses that API to add a top-level Finder menu item named **The Right Menu**, with submenu actions for creating files, duplicating items, copying paths, and opening Terminal.

## Features

- Create new files from the macOS menu bar with a save panel:
  - Plain Text
  - Markdown
  - JSON
  - Swift
  - HTML
  - CSS
  - JavaScript
  - Shell Script
- Create new named files from Finder:
  - Plain Text
  - Markdown
  - JSON
  - Swift
  - HTML
  - CSS
  - JavaScript
  - Shell Script
- Duplicate selected files or folders beside the original.
- Copy POSIX paths for selected items.
- Open Terminal at the current or selected folder.
- Show a menu bar control panel with setup instructions and Finder relaunch controls.

## Project Structure

```text
theRightMenu/
|-- theRightMenu/                    # Main macOS SwiftUI app
|   |-- ContentView.swift            # App UI and setup controls
|   |-- theRightMenuApp.swift        # SwiftUI app entry point
|   `-- theRightMenu.entitlements    # Main app sandbox entitlements
|-- RightMenuFinderExtension/        # Finder Sync extension
|   |-- FinderSync.swift             # Finder context menu implementation
|   |-- Info.plist                   # Finder Sync extension declaration
|   `-- RightMenuFinderExtension.entitlements
|-- theRightMenu.xcodeproj/
|-- LICENSE
`-- README.md
```

## Requirements

- macOS with Finder Sync extension support.
- Xcode with Swift and macOS SDK support.
- A valid Apple Developer signing identity for distributing public builds.

## Build Locally

From the repository root:

```sh
xcodebuild -project theRightMenu.xcodeproj -scheme theRightMenu -configuration Debug build
```

Or open `theRightMenu.xcodeproj` in Xcode and run the `theRightMenu` scheme.

## Enable the Finder Extension

After building and running the app, The Right Menu appears in the macOS menu bar. Finder actions require one extra system permission step:

1. Open **System Settings**.
2. Go to **General > Login Items & Extensions > Finder Extensions**.
3. Enable **The Right Menu**.
4. Relaunch Finder if the menu does not appear immediately.

You can also use the menu bar item's **Open Finder Extension Settings** and **Relaunch Finder** actions.

For local debugging, these commands are useful:

```sh
pluginkit -m -A -D -v -p com.apple.FinderSync | rg -C 2 -i "RightMenu|theRightMenu|com.reom"
pluginkit -e use -i com.reom.theRightMenu.FinderExtension
killall Finder
```

## Release Notes

The public product is the full macOS app, not just the Finder extension. The Finder Sync extension is embedded inside the app bundle at build time, so release artifacts should package and distribute `theRightMenu.app`.

A production release pipeline should:

1. Build the signed Release app.
2. Archive the app with Xcode.
3. Export the app using an `ExportOptions.plist`.
4. Notarize the exported app with Apple.
5. Staple the notarization ticket.
6. Package the notarized app as a `.dmg` or `.zip`.
7. Attach the package to a GitHub Release.

GitHub Actions can automate this, but the workflow will need Apple signing and notarization secrets. Do not commit certificates, provisioning profiles, app-specific passwords, API keys, or notarization credentials to the repository.

## Current Status

This project is in early implementation. The core Finder menu actions exist, but distribution still needs hardened runtime, release signing, notarization, and a GitHub Actions release workflow before it is ready for public users.

## License

MIT. See `LICENSE`.
