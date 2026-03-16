import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var hotKeyManager: HotkeyManager?
    private var dockManager: DockWindowManager?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up the dock window geometry and level.
        if let window = mainFlutterWindow {
            let mgr = DockWindowManager(window: window)
            mgr.setupAsDock()
            dockManager = mgr
        }

        // Register platform channel handlers.
        if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.snapd.app/native",
                binaryMessenger: controller.engine.binaryMessenger
            )
            let handler = PlatformChannelHandler(
                channel: channel,
                dockManager: dockManager
            )
            hotKeyManager = handler.hotkeyManager
            handler.register()
        }

        super.applicationDidFinishLaunching(notification)
    }

    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            mainFlutterWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
