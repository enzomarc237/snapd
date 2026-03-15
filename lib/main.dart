import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/command_management_screen.dart';
import 'screens/command_palette_screen.dart';
import 'services/command_service.dart';
import 'services/context_service.dart';
import 'services/platform_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise services.
  final commandService = CommandService();
  await commandService.load();

  final platformService = PlatformService();
  await platformService.registerGlobalHotkey();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: commandService),
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
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _HomeShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'SF Pro Text',
    );
  }
}

/// Root shell with a bottom navigation bar switching between the Command
/// Palette and the Command Management views.
class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _selectedIndex = 0;

  static const _screens = [
    CommandPaletteScreen(),
    CommandManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Palette',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Commands',
          ),
        ],
      ),
    );
  }
}
