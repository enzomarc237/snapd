import Cocoa
import FlutterMacOS

/// Routes Flutter method-channel calls to the appropriate native handler.
class PlatformChannelHandler {
    private let channel: FlutterMethodChannel
    let hotkeyManager: HotkeyManager
    private let shellExecutor: ShellExecutor
    private let contextDetector: ContextDetector

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        self.hotkeyManager = HotkeyManager()
        self.shellExecutor = ShellExecutor()
        self.contextDetector = ContextDetector()
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
    // MARK: – Window management
    // -------------------------------------------------------------------------

    private func handleToggleWindow(result: FlutterResult) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.mainWindow {
                if window.isVisible {
                    window.orderOut(nil)
                } else {
                    window.makeKeyAndOrderFront(nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
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
