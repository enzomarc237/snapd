import Cocoa
import FlutterMacOS

/// Routes Flutter method-channel calls to the appropriate native handler.
class PlatformChannelHandler {
    private let channel: FlutterMethodChannel
    let hotkeyManager: HotkeyManager
    private let shellExecutor: ShellExecutor
    private let contextDetector: ContextDetector
    private weak var dockManager: DockWindowManager?

    init(channel: FlutterMethodChannel, dockManager: DockWindowManager? = nil) {
        self.channel = channel
        self.hotkeyManager = HotkeyManager()
        self.shellExecutor = ShellExecutor()
        self.contextDetector = ContextDetector()
        self.dockManager = dockManager
    }

    func register() {
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "executeCommand":
                self.handleExecuteCommand(call: call, result: result)
            case "getActiveAppWorkingDirectory":
                self.handleGetActiveAppWorkingDirectory(result: result)
            case "getActiveAppBundleId":
                self.handleGetActiveAppBundleId(result: result)
            case "toggleWindow":
                self.handleToggleWindow(result: result)
            case "getScreenFrame":
                self.handleGetScreenFrame(result: result)
            case "initDockWindow":
                self.handleInitDockWindow(call: call, result: result)
            case "registerGlobalHotkey":
                self.handleRegisterGlobalHotkey(result: result)
            case "unregisterGlobalHotkey":
                self.handleUnregisterGlobalHotkey(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: – Shell execution
    // -------------------------------------------------------------------------

    private func handleExecuteCommand(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let script = args["script"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "script is required", details: nil))
            return
        }
        let workingDirectory = (args["workingDirectory"] as? String).flatMap {
            $0.isEmpty ? nil : $0
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let output = self.shellExecutor.execute(script: script,
                                                    workingDirectory: workingDirectory)
            DispatchQueue.main.async {
                result(output)
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: – Context detection
    // -------------------------------------------------------------------------

    private func handleGetActiveAppWorkingDirectory(result: @escaping FlutterResult) {
        let path = contextDetector.activeAppWorkingDirectory()
        result(path)
    }

    private func handleGetActiveAppBundleId(result: @escaping FlutterResult) {
        let bundleId = contextDetector.frontmostAppBundleId()
        result(bundleId)
    }

    // -------------------------------------------------------------------------
    // MARK: – Dock / window management
    // -------------------------------------------------------------------------

    private func handleToggleWindow(result: FlutterResult) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                window.orderOut(nil)
            } else if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
        result(nil)
    }

    private func handleGetScreenFrame(result: FlutterResult) {
        let frame = dockManager?.screenFrame() ?? [:]
        result(frame)
    }

    private func handleInitDockWindow(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
        }
        let height = args["height"] as? Double ?? Double(DockWindowManager.dockBarHeight)
        DispatchQueue.main.async { [weak self] in
            self?.dockManager?.positionAtBottom(height: CGFloat(height))
        }
        result(nil)
    }

    private func handleRegisterGlobalHotkey(result: FlutterResult) {
        hotkeyManager.register { [weak self] in
            self?.handleToggleWindow(result: { _ in })
        }
        result(nil)
    }

    private func handleUnregisterGlobalHotkey(result: FlutterResult) {
        hotkeyManager.unregister()
        result(nil)
    }
}
