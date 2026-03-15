import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/ai_agents_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/command_palette_screen.dart';
import 'screens/dev_tools_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ai_agent_service.dart';
import 'services/ai_chat_service.dart';
import 'services/command_service.dart';
import 'services/context_service.dart';
import 'services/dock_window_service.dart';
import 'services/platform_service.dart';
import 'widgets/dock_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Boot services in parallel.
  final commandService = CommandService();
  final agentService = AiAgentService();
  await Future.wait([
    commandService.load(),
    agentService.load(),
  ]);

  final platformService = PlatformService();
  final dockWindowService = DockWindowService();

  // Configure the window as a floating dock.
  const WindowOptions windowOptions = WindowOptions(
    size: Size(DockWindowService.dockWidth, DockWindowService.dockBarHeight),
    minimumSize:
        Size(DockWindowService.dockWidth, DockWindowService.dockBarHeight),
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions);

  // Position at bottom of screen and register hotkey.
  await dockWindowService.initialize();
  await platformService.registerGlobalHotkey();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: commandService),
        ChangeNotifierProvider.value(value: agentService),
        ChangeNotifierProvider(create: (_) => AiChatService()),
        ChangeNotifierProvider.value(value: dockWindowService),
        ChangeNotifierProvider(create: (_) => ContextService()),
        Provider.value(value: platformService),
      ],
      child: const SnapdApp(),
    ),
  );
}

class SnapdApp extends StatelessWidget {
  const SnapdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snapd',
      debugShowCheckedModeBanner: false,
      // Always dark – dock lives on top of the user's desktop.
      theme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const DockShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // indigo accent
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}

/// The floating developer dock shell.
///
/// Layout (window grows upward when a panel opens):
/// ```
/// ┌──────────────────────────────────────────┐
/// │  Panel area (AnimatedSwitcher, 0→420px)  │
/// ├──────────────────────────────────────────┤
/// │  Dock bar  (always 72px)                 │
/// └──────────────────────────────────────────┘
/// ```
class DockShell extends StatefulWidget {
  const DockShell({super.key});

  @override
  State<DockShell> createState() => _DockShellState();
}

class _DockShellState extends State<DockShell> with WindowListener {
  DockSection? _activeSection;

  // Keep one instance of each panel so their state is preserved between visits.
  static const _panels = {
    DockSection.terminal: CommandPaletteScreen(),
    DockSection.aiChat: AiChatScreen(),
    DockSection.aiAgents: AiAgentsScreen(),
    DockSection.devTools: DevToolsScreen(),
    DockSection.settings: SettingsScreen(),
  };

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _onDockItemTap(DockSection section) async {
    final dockSvc = context.read<DockWindowService>();
    if (_activeSection == section) {
      // Same item tapped → collapse.
      setState(() => _activeSection = null);
      await dockSvc.collapse();
    } else {
      final wasCollapsed = _activeSection == null;
      setState(() => _activeSection = section);
      if (wasCollapsed) await dockSvc.expand();
    }
  }

  Future<void> _closePanel() async {
    if (_activeSection == null) return;
    setState(() => _activeSection = null);
    await context.read<DockWindowService>().collapse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.escape) {
            _closePanel();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Panel area – zero height when collapsed.
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _activeSection != null
                    ? _PanelContainer(
                        key: ValueKey(_activeSection),
                        onClose: _closePanel,
                        child: _panels[_activeSection]!,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            // Dock bar – always visible.
            DockBar(
              activeSection: _activeSection,
              onSectionTap: _onDockItemTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted-glass panel container that appears above the dock bar.
class _PanelContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;

  const _PanelContainer({
    super.key,
    required this.child,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A).withOpacity(0.88),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
