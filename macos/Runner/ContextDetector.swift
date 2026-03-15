import Cocoa

/// Detects context information about the currently active macOS application,
/// including its bundle identifier and (where possible) working directory.
class ContextDetector {
    /// Returns the bundle identifier of the frontmost application.
    func frontmostAppBundleId() -> String? {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    /// Attempts to return the working directory of the frontmost Terminal or
    /// editor application, falling back to nil.
    ///
    /// - For Terminal.app and iTerm, we retrieve the current tab's directory
    ///   via AppleScript.
    /// - For other apps we return nil (the Flutter side falls back to the
    ///   process working directory).
    func activeAppWorkingDirectory() -> String? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let bundleId = app.bundleIdentifier ?? ""

        switch bundleId {
        case "com.apple.Terminal":
            return terminalWorkingDirectory()
        case "com.googlecode.iterm2":
            return iTermWorkingDirectory()
        default:
            return nil
        }
    }

    // -------------------------------------------------------------------------
    // MARK: – AppleScript helpers
    // -------------------------------------------------------------------------

    private func terminalWorkingDirectory() -> String? {
        let script = """
        tell application "Terminal"
            set frontTab to selected tab of front window
            return custom title of frontTab
        end tell
        """
        // The custom title may not be the path; use tty-based approach instead.
        // Return the working directory of the active Terminal process.
        return runAppleScript("""
        tell application "Terminal"
            set ttyPath to tty of selected tab of front window
            return ttyPath
        end tell
        """).flatMap { tty in
            workingDirectoryForTTY(tty)
        }
    }

    private func iTermWorkingDirectory() -> String? {
        return runAppleScript("""
        tell application "iTerm"
            tell current window
                tell current session
                    return variable named "session.path"
                end tell
            end tell
        end tell
        """)
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)
        guard error == nil else { return nil }
        return result?.stringValue
    }

    private func workingDirectoryForTTY(_ tty: String) -> String? {
        // Strip the "/dev/" prefix to get the tty name used by `ps`.
        let ttyName = tty.replacingOccurrences(of: "/dev/", with: "")

        // Find the PID of the shell process attached to this tty.
        let findPidScript = "ps -t \(ttyName) -o pid= | head -1"

        // Use lsof to read the current working directory of that PID.
        // The -F n flag outputs the filename field (prefixed with 'n'),
        // and sed strips that prefix.
        let script = """
        pid=$(\(findPidScript))
        if [ -n "$pid" ]; then
            lsof -a -p "$pid" -d cwd -F n | tail -1 | sed 's/^n//'
        fi
        """
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", script]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return str?.isEmpty == false ? str : nil
    }
}
