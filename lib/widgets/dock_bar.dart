import 'dart:ui';

import 'package:flutter/material.dart';

/// Sections surfaced as dock items.
enum DockSection {
  terminal,
  aiChat,
  aiAgents,
  devTools,
  settings,
}

extension DockSectionX on DockSection {
  String get label {
    switch (this) {
      case DockSection.terminal:
        return 'Shell';
      case DockSection.aiChat:
        return 'AI Chat';
      case DockSection.aiAgents:
        return 'Agents';
      case DockSection.devTools:
        return 'Dev Tools';
      case DockSection.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case DockSection.terminal:
        return Icons.terminal;
      case DockSection.aiChat:
        return Icons.chat_bubble_outline_rounded;
      case DockSection.aiAgents:
        return Icons.smart_toy_outlined;
      case DockSection.devTools:
        return Icons.build_outlined;
      case DockSection.settings:
        return Icons.tune;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case DockSection.terminal:
        return Icons.terminal;
      case DockSection.aiChat:
        return Icons.chat_bubble_rounded;
      case DockSection.aiAgents:
        return Icons.smart_toy;
      case DockSection.devTools:
        return Icons.build;
      case DockSection.settings:
        return Icons.tune;
    }
  }

  Color get accentColor {
    switch (this) {
      case DockSection.terminal:
        return const Color(0xFF4ADE80); // green
      case DockSection.aiChat:
        return const Color(0xFF60A5FA); // blue
      case DockSection.aiAgents:
        return const Color(0xFFA78BFA); // purple
      case DockSection.devTools:
        return const Color(0xFFFBBF24); // amber
      case DockSection.settings:
        return const Color(0xFF94A3B8); // slate
    }
  }
}

/// The persistent, frosted-glass dock bar at the bottom of the screen.
///
/// Renders a row of [DockSection] icons. Tapping an icon toggles the
/// corresponding panel open/closed.
class DockBar extends StatelessWidget {
  final DockSection? activeSection;
  final void Function(DockSection) onSectionTap;

  const DockBar({
    super.key,
    required this.activeSection,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.80),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: DockSection.values
                  .map((section) => _DockIcon(
                        section: section,
                        isActive: activeSection == section,
                        onTap: () => onSectionTap(section),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatefulWidget {
  final DockSection section;
  final bool isActive;
  final VoidCallback onTap;

  const _DockIcon({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChange(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final isActive = widget.isActive;
    final color = isActive || _isHovered
        ? section.accentColor
        : Colors.white.withOpacity(0.65);

    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SizedBox(
            width: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: isActive
                      ? BoxDecoration(
                          color: section.accentColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: section.accentColor.withOpacity(0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    isActive ? section.activeIcon : section.icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  section.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                // Active indicator dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 4 : 0,
                  height: isActive ? 4 : 0,
                  decoration: BoxDecoration(
                    color: section.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
