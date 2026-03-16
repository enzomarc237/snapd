import Cocoa
import FlutterMacOS

/// The main application window configured as a transparent dock container.
///
/// Actual dock positioning and window level are applied by [DockWindowManager]
/// after the Flutter engine is ready. This class just wires up the engine and
/// clears the default macOS chrome so the window starts borderless.
class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        // Strip all window chrome – the dock widget provides its own visuals.
        self.styleMask = [.borderless, .fullSizeContentView]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = false
        self.hasShadow = false

        // Allow the transparent Flutter surface to draw properly.
        if let contentView = self.contentView {
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = CGColor.clear
        }

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
