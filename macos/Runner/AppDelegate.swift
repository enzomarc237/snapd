import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var hotKeyManager: HotkeyManager?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure always-on-top floating window.
        if let window = mainFlutterWindow {
            window.level = .floating
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
            ]
            window.isMovableByWindowBackground = true
        }

        // Register platform channel handlers.
        if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.snapd.app/native",
                binaryMessenger: controller.engine.binaryMessenger
            )
            let handler = PlatformChannelHandler(channel: channel)
            hotKeyManager = handler.hotkeyManager
            handler.register()
        }

        super.applicationDidFinishLaunching(notification)
    }

    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            mainFlutterWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
