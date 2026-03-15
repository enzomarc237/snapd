import Foundation

/// Executes shell scripts using `/bin/zsh -c` and captures stdout, stderr,
/// and the exit code.
class ShellExecutor {
    /// Executes [script] and returns a dictionary with keys:
    ///   - `stdout`: String
    ///   - `stderr`: String
    ///   - `exitCode`: Int
    func execute(script: String, workingDirectory: String? = nil) -> [String: Any] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]

        if let wd = workingDirectory, !wd.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: wd)
        } else if let home = ProcessInfo.processInfo.environment["HOME"] {
            process.currentDirectoryURL = URL(fileURLWithPath: home)
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return [
                "stdout": "",
                "stderr": error.localizedDescription,
                "exitCode": -1,
            ]
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return [
            "stdout": String(data: stdoutData, encoding: .utf8) ?? "",
            "stderr": String(data: stderrData, encoding: .utf8) ?? "",
            "exitCode": Int(process.terminationStatus),
        ]
    }
}
