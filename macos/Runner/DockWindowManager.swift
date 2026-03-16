import Cocoa

/// Manages the macOS window to behave as a persistent floating dock bar.
///
/// The window is:
/// - Pinned to the bottom-centre of the primary screen
/// - At `.statusBar` window level (above normal apps, below menu bar)
/// - Borderless with a transparent background
/// - Excluded from Mission Control / Exposé cycling
class DockWindowManager {
    private let window: NSWindow

    // Dock geometry constants (match Dart-side DockWindowService).
    static let dockWidth: CGFloat = 700
    static let dockBarHeight: CGFloat = 72
    static let bottomPadding: CGFloat = 20

    init(window: NSWindow) {
        self.window = window
    }

    /// Configures the window style and positions it at the screen bottom.
    func setupAsDock() {
        // ── Style ────────────────────────────────────────────────────────────
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovableByWindowBackground = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // ── Window level ─────────────────────────────────────────────────────
        // .statusBar sits above regular windows but below the menu bar.
        window.level = NSWindow.Level.statusBar

        // ── Collection behaviour ─────────────────────────────────────────────
        // Visible on all Spaces, never shown in Exposé/Mission Control.
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary,
        ]

        // ── Initial frame ────────────────────────────────────────────────────
        positionAtBottom(height: Self.dockBarHeight)
    }

    /// Positions the window at the bottom-centre of the primary screen.
    func positionAtBottom(height: CGFloat) {
        guard let screen = primaryScreen() else { return }
        let screenFrame = screen.frame
        let x = screenFrame.minX + (screenFrame.width - Self.dockWidth) / 2
        let y = screenFrame.minY + Self.bottomPadding
        let frame = NSRect(
            x: x,
            y: y,
            width: Self.dockWidth,
            height: height
        )
        window.setFrame(frame, display: true, animate: false)
    }

    /// Returns the primary screen's frame and visible frame as a dictionary
    /// (used by the Flutter side via the platform channel).
    func screenFrame() -> [String: Double] {
        guard let screen = primaryScreen() else { return [:] }
        let f = screen.frame
        let v = screen.visibleFrame
        return [
            "width":         Double(f.width),
            "height":        Double(f.height),
            "x":             Double(f.minX),
            "y":             Double(f.minY),
            "visibleWidth":  Double(v.width),
            "visibleHeight": Double(v.height),
            "visibleX":      Double(v.minX),
            "visibleY":      Double(v.minY),
        ]
    }

    // -------------------------------------------------------------------------
    // MARK: – Private
    // -------------------------------------------------------------------------

    private func primaryScreen() -> NSScreen? {
        // NSScreen.main is the screen with the key window; .screens.first has
        // the menu bar. Use screens.first so we always anchor to the menu-bar
        // screen regardless of focus.
        return NSScreen.screens.first ?? NSScreen.main
    }
}
