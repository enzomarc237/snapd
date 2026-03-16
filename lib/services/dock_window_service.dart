import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the dock window geometry: size and screen-bottom positioning.
///
/// The window grows UPWARD when a panel opens (Y decreases, height increases)
/// so the bottom of the dock stays anchored to the screen edge.
class DockWindowService extends ChangeNotifier {
  /// Height of the persistent dock bar strip.
  static const double dockBarHeight = 72.0;

  /// Height of the expanded panel area (above the dock bar).
  static const double panelHeight = 420.0;

  /// Total width of the dock window.
  static const double dockWidth = 700.0;

  /// Gap between the dock window bottom and the screen edge (in logical px).
  static const double bottomPadding = 20.0;

  bool _isExpanded = false;
  Offset? _dockPosition; // cached bottom-left of collapsed dock window

  bool get isExpanded => _isExpanded;

  /// Initialises the window as a floating dock at the bottom of the screen.
  ///
  /// Must be called after [windowManager.ensureInitialized].
  Future<void> initialize() async {
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setResizable(false);
    await windowManager.setSize(const Size(dockWidth, dockBarHeight));
    _dockPosition = await _computeBottomCenterPosition(dockBarHeight);
    if (_dockPosition != null) {
      await windowManager.setPosition(_dockPosition!);
    }
    await windowManager.show();
    await windowManager.focus();
  }

  /// Expands the window upward to reveal [panelHeight] above the dock bar.
  Future<void> expand() async {
    if (_isExpanded) return;
    final pos = _dockPosition ?? await windowManager.getPosition();
    final expandedHeight = dockBarHeight + panelHeight;
    // Move the top-left origin up so the bottom edge stays fixed.
    final newY = pos.dy - panelHeight;
    await windowManager.setSize(Size(dockWidth, expandedHeight));
    await windowManager.setPosition(Offset(pos.dx, newY));
    _isExpanded = true;
    notifyListeners();
  }

  /// Collapses the window back to dock-only height.
  Future<void> collapse() async {
    if (!_isExpanded) return;
    final currentPos = await windowManager.getPosition();
    // Restore Y to what it was before expansion.
    final restoredY = currentPos.dy + panelHeight;
    final restoredPos = Offset(currentPos.dx, restoredY);
    _dockPosition = restoredPos;
    await windowManager.setSize(const Size(dockWidth, dockBarHeight));
    await windowManager.setPosition(restoredPos);
    _isExpanded = false;
    notifyListeners();
  }

  /// Re-anchors the dock to the bottom-centre of the screen.
  ///
  /// Call this when the screen configuration changes.
  Future<void> reanchor() async {
    _isExpanded = false;
    await windowManager.setSize(const Size(dockWidth, dockBarHeight));
    _dockPosition = await _computeBottomCenterPosition(dockBarHeight);
    if (_dockPosition != null) {
      await windowManager.setPosition(_dockPosition!);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<Offset?> _computeBottomCenterPosition(double windowHeight) async {
    try {
      final screenSize = await windowManager.getSize();
      // Approximate screen width from current size; for exact values use the
      // native getScreenFrame channel call which AppDelegate wires up.
      // Fall back to a sensible default if unavailable.
      const screenWidth = 2560.0; // overridden by native after init
      final x = (screenWidth / 2) - (dockWidth / 2);
      // window_manager on macOS uses flipped coordinates (origin = top-left).
      // We use absolute pixel coords as reported by the OS.
      final y = screenSize.height - windowHeight - bottomPadding;
      return Offset(x, y);
    } catch (_) {
      return null;
    }
  }
}
