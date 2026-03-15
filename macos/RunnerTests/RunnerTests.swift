import XCTest

/// Basic macOS-side unit tests for the native helper classes.
/// These run without a full Flutter engine.
class RunnerTests: XCTestCase {

    // -------------------------------------------------------------------------
    // MARK: – ShellExecutor
    // -------------------------------------------------------------------------

    func testShellExecutorSuccess() {
        let executor = ShellExecutor()
        let result = executor.execute(script: "echo hello")
        XCTAssertEqual(result["exitCode"] as? Int, 0)
        XCTAssertTrue((result["stdout"] as? String ?? "").contains("hello"))
        XCTAssertEqual(result["stderr"] as? String, "")
    }

    func testShellExecutorFailure() {
        let executor = ShellExecutor()
        let result = executor.execute(script: "exit 1")
        XCTAssertEqual(result["exitCode"] as? Int, 1)
    }

    func testShellExecutorStderr() {
        let executor = ShellExecutor()
        let result = executor.execute(script: "echo error >&2; exit 2")
        XCTAssertEqual(result["exitCode"] as? Int, 2)
        XCTAssertTrue((result["stderr"] as? String ?? "").contains("error"))
    }

    func testShellExecutorWithWorkingDirectory() {
        let executor = ShellExecutor()
        let tmpDir = NSTemporaryDirectory()
        let result = executor.execute(script: "pwd", workingDirectory: tmpDir)
        XCTAssertEqual(result["exitCode"] as? Int, 0)
        let stdout = (result["stdout"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        // Resolve symlinks since /tmp -> /private/tmp on macOS.
        let resolvedTmp = URL(fileURLWithPath: tmpDir).resolvingSymlinksInPath().path
        XCTAssertTrue(stdout.hasPrefix(resolvedTmp), "Expected '\(stdout)' to start with '\(resolvedTmp)'")
    }

    // -------------------------------------------------------------------------
    // MARK: – ContextDetector
    // -------------------------------------------------------------------------

    func testContextDetectorDoesNotCrash() {
        let detector = ContextDetector()
        _ = detector.frontmostAppBundleId()
        _ = detector.activeAppWorkingDirectory()
    }
}
