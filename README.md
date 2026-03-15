# Snapd — Floating Developer Dock

A persistent, always-on-top **floating dock for macOS**, built with **Flutter + Swift**, designed specifically for developers. It lives at the bottom of your screen like the macOS Dock but surfaces the tools you actually use: a shell runner, AI agents/chat, dev shortcuts, and more.

```
┌──────────────────────────────────────────────────────────────┐
│  ╔══════════════════════════════════════════════════════════╗ │
│  ║   Panel area – slides up when a dock item is tapped      ║ │
│  ║   (Terminal · AI Chat · Agents · Dev Tools · Settings)   ║ │
│  ╚══════════════════════════════════════════════════════════╝ │
│  ╔══════════════════════════════════════════════════════════╗ │
│  ║  🖥️ Shell   💬 AI Chat   �� Agents   🔧 Dev Tools  ⚙️  ║ │  ← Dock bar (frosted glass pill)
│  ╚══════════════════════════════════════════════════════════╝ │
└──────────────────────────────────────────────────────────────┘
                           Screen bottom
```

## Dock panels

| Icon | Panel | What it does |
|------|-------|--------------|
| 🖥️ | **Shell** | Fuzzy-search & run custom scripts; keyboard navigation; contextual project awareness |
| 💬 | **AI Chat** | Chat with any configured AI agent (OpenAI, Anthropic, Ollama, Gemini, custom) |
| 🤖 | **Agents** | Add / edit / enable-disable AI agents with API keys, models, system prompts |
| 🔧 | **Dev Tools** | One-tap Git, npm, Python, Go, Docker shortcut buttons with live output |
| ⚙️ | **Settings** | Dock options, hotkeys, provider info |

## Architecture

```
Flutter UI (Dart)
    ↓  MethodChannel "com.snapd.app/native"
macOS Native (Swift)
    ├── DockWindowManager  – borderless window at NSWindowLevel.statusBar
    ├── ShellExecutor      – runs scripts via /bin/zsh
    ├── HotkeyManager      – ⌘Space system-wide toggle via Carbon API
    ├── ContextDetector    – detects frontmost app / working directory
    └── PlatformChannelHandler – routes Flutter calls to native helpers
```

## Window behaviour

- **Persistent dock** — lives at the screen bottom at all times (no summon hotkey needed)
- **Expands upward** — clicking a dock item grows the window height upward (bottom stays fixed)
- **Frosted glass** — `BackdropFilter` blur over whatever is behind the window
- **⌘Space** — global hotkey to show/hide the dock
- **NSWindowLevel.statusBar** — above all normal app windows, below the menu bar
- **All Spaces** — `canJoinAllSpaces` + `stationary` + `ignoresCycle` collection behaviours

## AI features

- Connect any **OpenAI-compatible** provider (OpenAI, Anthropic, Google Gemini, Ollama, custom)
- Run **Ollama locally** at `http://localhost:11434` with zero configuration
- Multi-turn conversation history (last 20 messages sent as context)
- Per-agent system prompts, model selection, and API key storage
- Enable/disable agents individually

## Project structure

```
lib/
  main.dart                          – DockShell entry point
  models/
    ai_agent.dart                    – AI agent config (provider, model, key, prompt)
    chat_message.dart                – Chat turn model
    command.dart                     – Shell command model
    command_result.dart              – Shell execution result
    project_context.dart             – Detected project type
  services/
    ai_agent_service.dart            – Agent CRUD + JSON persistence
    ai_chat_service.dart             – HTTP chat completions (OpenAI-compatible)
    command_service.dart             – Shell command CRUD + persistence
    context_service.dart             – Project-type detection from marker files
    dock_window_service.dart         – Window expand/collapse via window_manager
    platform_service.dart            – Flutter ↔ Swift platform channel bridge
  screens/
    ai_agents_screen.dart            – Agent management panel
    ai_chat_screen.dart              – Chat interface panel
    command_palette_screen.dart      – Shell search & run panel
    command_management_screen.dart   – Shell command CRUD panel
    dev_tools_screen.dart            – Git/npm/Python/Go/Docker quick-action panel
    settings_screen.dart             – Dock settings panel
  widgets/
    dock_bar.dart                    – Frosted-glass dock bar with hover animations
    command_form.dart                – Shell command editor form
    command_list_item.dart           – Shell command list row

macos/Runner/
  AppDelegate.swift                  – App lifecycle + DockWindowManager init
  MainFlutterWindow.swift            – Borderless transparent window
  DockWindowManager.swift            – Dock positioning, level, collection behaviour
  PlatformChannelHandler.swift       – Routes method-channel calls
  HotkeyManager.swift                – Carbon API global hotkey (⌘Space)
  ShellExecutor.swift                – /bin/zsh script runner
  ContextDetector.swift              – NSWorkspace + AppleScript context detection
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
# .app → build/macos/Build/Products/Release/snapd.app
```

### Tests

```bash
# Dart unit tests
flutter test

# macOS Swift unit tests
xcodebuild test -workspace macos/Runner.xcworkspace \
  -scheme Runner -destination 'platform=macOS'
```

## Success metrics

- ✅ Always visible – no need to summon it with a hotkey (but ⌘Space still works)
- ✅ Panel opens in < 250 ms (animated window resize)
- ✅ Shell command execution < 500 ms
- ✅ App footprint < 50 MB
- ✅ Works with any OpenAI-compatible AI provider including local Ollama
