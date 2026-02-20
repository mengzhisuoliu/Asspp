# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Asspp is a multi-account App Store management app (iOS + macOS) for searching, downloading, and installing IPA files. It uses an Xcode workspace (`Asspp.xcworkspace`) with a local Swift package (`Foundation/ApplePackage`) that provides the core App Store protocol implementation.

## Build Commands

```bash
# Build for iOS (device)
xcodebuild -workspace Asspp.xcworkspace -scheme Asspp -configuration Debug -destination 'generic/platform=iOS' build

# Build for macOS
xcodebuild -workspace Asspp.xcworkspace -scheme Asspp -configuration Debug -destination 'platform=macOS' build

# Build for iOS simulator
xcodebuild -workspace Asspp.xcworkspace -scheme Asspp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build

# CI release build (iOS IPA, unsigned)
./Resources/Scripts/compile.release.mobile.ci.sh "$(pwd)" "$(pwd)/Asspp.ipa"

# CI release build (macOS zip)
./Resources/Scripts/compile.release.osx.sh "$(pwd)" "$(pwd)/Asspp.zip"
```

**Important**: Always use `Asspp.xcworkspace` (not `.xcodeproj`) because the workspace includes the local `ApplePackage` package. Always pipe xcodebuild output through `xcbeautify` (e.g. `xcodebuild ... | xcbeautify`) to reduce output verbosity and save tokens.

## Code Signing Setup

`Configuration/Developer.xcconfig` is gitignored and must exist for builds. It provides code signing settings:

```
DEVELOPMENT_TEAM = <your team ID>
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = Apple Development
```

The build has a shell script phase that errors if this file is missing.

## Build Configuration

xcconfig hierarchy: `Debug.xcconfig`/`Release.xcconfig` → `Base.xcconfig` → `Version.xcconfig`, plus `Developer.xcconfig` for signing. Version numbers are in `Configuration/Version.xcconfig` (single source of truth).

Deployment targets: iOS 15.0, macOS 15.0. Supports iPhone, iPad, and Mac (native, not Catalyst).

## Architecture

### Backend Layer (`Asspp/Backend/`)

- **AppStore/**: Account management (`AppStore` singleton), authentication (`AuthenticationService`), package/archive models (`AppPackage`, `AppPackageArchive`, `UserAccount`). Uses `ApplePackage` library for App Store protocol.
- **Downloader/**: `Downloads` singleton manages download queue via `Digger` library. `PackageManifest` tracks download state and IPA signature injection. `PackageState` models download progress.
- **Installer/**: iOS-only local HTTPS server (Vapor) that serves IPA files for OTA installation via `itms-services://` protocol. Uses TLS certs from `Certificates/` bundle. Extensions handle app manifest, compute, image, and TLS setup.
- **DeviceCTL/**: macOS-only device management via `devicectl` CLI. `DeviceManager` handles app installation to connected iOS devices and update checking.
- **MD5/**: MD5 hash utility.

### Interface Layer (`Asspp/Interface/`)

SwiftUI views organized by feature: Account, Search, Download, Installed (macOS only), Setting, Welcome. `MainView` switches between `NavigationSplitView` sidebar (macOS) and `TabView` (iOS), with iOS 18+ using the new `Tab` API.

### Key Patterns

- **Persistence**: Custom `@PublishedPersist` / `@Persist` property wrappers (in `Extension/PublishedPersist.swift`) back `ObservableObject` properties to file storage or Keychain. Accounts are stored in Keychain; downloads and settings use file storage.
- **Platform branching**: Heavy use of `#if os(macOS)` / `#if os(iOS)` / `#if canImport(UIKit)` for platform-specific code paths.
- **Singletons**: `AppStore.this`, `Downloads.this` are `@MainActor` singletons accessed as `@StateObject` in views.
- **ApplePackage**: Local SPM package in `Foundation/ApplePackage/` — the core library for App Store API communication, IPA handling, and signature injection. Also available as a standalone CLI tool.

## Dependencies (SPM via Xcode)

- **ApplePackage** (local) — App Store protocol, IPA handling
- **Vapor** — HTTPS server for iOS OTA installation
- **swift-nio / swift-nio-ssl** — Networking (Vapor dependency, also used directly)
- **Digger** — Download manager with progress/speed tracking
- **Kingfisher** — Async image loading
- **ColorfulX** — Gradient animations (welcome screen)
- **KeychainAccess** — Keychain storage for accounts
- **AnyCodable** — Type-erased Codable values
- **Dynamic** — Dynamic member lookup for ObjC runtime
- **swift-log** — Structured logging (`logger` global)

# Swift Code Style Guidelines

## Core Style

- **Indentation**: 4 spaces
- **Braces**: Opening brace on same line
- **Spacing**: Single space around operators and commas
- **Naming**: PascalCase for types, camelCase for properties/methods

## File Organization

- Logical directory grouping
- PascalCase files for types, `+` for extensions
- Modular design with extensions

## Modern Swift Features

- **@Observable macro**: Replace `ObservableObject`/`@Published`
- **Swift concurrency**: `async/await`, `Task`, `actor`, `@MainActor`
- **Result builders**: Declarative APIs
- **Property wrappers**: Use line breaks for long declarations
- **Opaque types**: `some` for protocol returns

## Code Structure

- Early returns to reduce nesting
- Guard statements for optional unwrapping
- Single responsibility per type/extension
- Value types over reference types

## Error Handling

- `Result` enum for typed errors
- `throws`/`try` for propagation
- Optional chaining with `guard let`/`if let`
- Typed error definitions

## Architecture

- Protocol-oriented design
- Dependency injection over singletons
- Composition over inheritance
- Factory/Repository patterns

## Debug Assertions

- Use `assert()` for development-time invariant checking
- Use `assertionFailure()` for unreachable code paths
- Assertions removed in release builds for performance
- Precondition checking with `precondition()` for fatal errors

## Memory Management

- `weak` references for cycles
- `unowned` when guaranteed non-nil
- Capture lists in closures
- `deinit` for cleanup
