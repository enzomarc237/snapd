# Snapd — macOS Command Palette

A lightweight, always-on-top macOS app built with **Flutter + Swift** that lets you search and execute custom shell scripts from a keyboard-driven floating window.

## Features

| Feature | Details |
|---|---|
| **Command Palette** | Fuzzy search over all commands; keyboard navigation (↑ / ↓), run with ↵, dismiss with Esc |
| **Global Hotkey** | ⌘Space toggles the floating window from any app |
| **Contextual Awareness** | Detects active project type (Node.js, Python, Go, Rust, Ruby, Java) and surfaces relevant commands first |
| **Floating Window** | Always-on-top, draggable, rounded-corner window |
| **Command Management** | Add, edit and delete commands via a clean UI; name and script are validated before saving |
| **Persistence** | Commands are saved to JSON in the macOS Application Support directory and loaded on every launch |

## Architecture

```
Flutter UI (Dart)
    ↓  MethodChannel "com.snapd.app/native"
macOS Native (Swift)
    ├── ShellExecutor      – runs scripts via /bin/zsh
    ├── HotkeyManager      – registers ⌘Space system-wide via Carbon API
    ├── ContextDetector    – detects frontmost app / working directory
    └── PlatformChannelHandler – routes Flutter calls to native helpers
```

## Project structure

```
lib/
  main.dart                        – app entry point
  models/
    command.dart                   – Command value object + JSON serialisation
    command_result.dart            – Shell execution result
    project_context.dart           – Detected project type
  services/
    command_service.dart           – CRUD + persistence (JSON)
    context_service.dart           – Project-type detection from directory markers
    platform_service.dart          – Flutter ↔ Swift platform channel bridge
  screens/
    command_palette_screen.dart    – Main palette UI (search, run, keyboard nav)
    command_management_screen.dart – Add / edit / delete commands
  widgets/
    command_list_item.dart         – Single command row widget
    command_form.dart              – Validated form for creating / editing commands

macos/Runner/
  AppDelegate.swift                – App lifecycle + window level
  MainFlutterWindow.swift          – Floating, rounded-corner window
  PlatformChannelHandler.swift     – Routes method-channel calls
  HotkeyManager.swift              – Carbon API global hotkey (⌘Space)
  ShellExecutor.swift              – Runs scripts with /bin/zsh
  ContextDetector.swift            – Frontmost app + working directory detection
```

## Getting started

### Prerequisites

- macOS 10.14+
- Flutter ≥ 3.10 (`flutter --version`)
- Xcode 14+

### Run

```bash
flutter pub get
flutter run -d macos
```

### Build release .dmg

```bash
flutter build macos --release
# The .app is in build/macos/Build/Products/Release/snapd.app
```

### Tests

```bash
# Dart unit tests
flutter test

# macOS (Swift) unit tests
xcodebuild test -workspace macos/Runner.xcworkspace \
  -scheme Runner -destination 'platform=macOS'
```

## Success metrics

- ✅ Command execution < 500 ms
- ✅ App footprint < 50 MB
- ✅ Keyboard-first UX (no mouse required for core flow)
