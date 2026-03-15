import 'package:flutter/services.dart';

import '../models/command_result.dart';

/// Bridge to native macOS code via platform channels.
///
/// Handles shell execution, active window detection, window management, and
/// dock window positioning.
class PlatformService {
  static const _channel = MethodChannel('com.snapd.app/native');

  // ---------------------------------------------------------------------------
  // Shell execution
  // ---------------------------------------------------------------------------

  /// Executes [script] via the native shell and returns the result.
  ///
  /// The [workingDirectory] defaults to the user's home directory if not set.
  Future<CommandResult> executeCommand(
    String script, {
    String? workingDirectory,
  }) async {
    final start = DateTime.now();
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('executeCommand', {
        'script': script,
        'workingDirectory': workingDirectory ?? '',
      });
      final duration = DateTime.now().difference(start);
      return CommandResult(
        stdout: (result['stdout'] as String?) ?? '',
        stderr: (result['stderr'] as String?) ?? '',
        exitCode: (result['exitCode'] as int?) ?? -1,
        duration: duration,
      );
    } on PlatformException catch (e) {
      return CommandResult(
        stdout: '',
        stderr: e.message ?? 'Unknown platform error',
        exitCode: -1,
        duration: DateTime.now().difference(start),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Context / active app detection
  // ---------------------------------------------------------------------------

  /// Returns the path of the frontmost application's current working directory,
  /// or null if it cannot be determined.
  Future<String?> getActiveAppWorkingDirectory() async {
    try {
      final String? path =
          await _channel.invokeMethod('getActiveAppWorkingDirectory');
      return path;
    } on PlatformException {
      return null;
    }
  }

  /// Returns the bundle identifier of the frontmost application.
  Future<String?> getActiveAppBundleId() async {
    try {
      final String? bundleId =
          await _channel.invokeMethod('getActiveAppBundleId');
      return bundleId;
    } on PlatformException {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Window / dock management
  // ---------------------------------------------------------------------------

  /// Toggles the visibility of the main window.
  Future<void> toggleWindow() async {
    try {
      await _channel.invokeMethod('toggleWindow');
    } on PlatformException {
      // Non-fatal – ignore.
    }
  }

  /// Returns the primary screen frame (full and visible area) in logical pixels.
  ///
  /// Keys: `width`, `height`, `x`, `y`, `visibleWidth`, `visibleHeight`,
  ///       `visibleX`, `visibleY`.
  Future<Map<String, double>> getScreenFrame() async {
    try {
      final raw =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getScreenFrame');
      return raw?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
          {};
    } on PlatformException {
      return {};
    }
  }

  /// Positions and sizes the window as a dock pinned to the screen bottom.
  ///
  /// Called from [DockWindowService.initialize] via the native side so that
  /// initial placement is exact (avoids window_manager's coordinate mapping
  /// quirks on first launch).
  Future<void> initDockWindow({
    required double width,
    required double height,
    required double bottomPadding,
  }) async {
    try {
      await _channel.invokeMethod('initDockWindow', {
        'width': width,
        'height': height,
        'bottomPadding': bottomPadding,
      });
    } on PlatformException {
      // Non-fatal – window_manager fallback is used instead.
    }
  }

  /// Registers the global hotkey for toggling the dock (⌘Space by default).
  Future<void> registerGlobalHotkey() async {
    try {
      await _channel.invokeMethod('registerGlobalHotkey');
    } on PlatformException {
      // Non-fatal – ignore.
    }
  }

  /// Unregisters the global hotkey.
  Future<void> unregisterGlobalHotkey() async {
    try {
      await _channel.invokeMethod('unregisterGlobalHotkey');
    } on PlatformException {
      // Non-fatal – ignore.
    }
  }
}

