import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/command.dart';
import '../models/command_result.dart';
import '../models/project_context.dart';
import '../services/command_service.dart';
import '../services/context_service.dart';
import '../services/platform_service.dart';
import '../widgets/command_list_item.dart';

/// The main Command Palette screen.
///
/// Features:
/// - Fuzzy search over commands (name, description, tags)
/// - Contextual awareness: highlights commands relevant to the active project
/// - Keyboard navigation (↑ / ↓ to select, ↵ to run, Esc to clear / close)
/// - Command execution via the platform channel
class CommandPaletteScreen extends StatefulWidget {
  const CommandPaletteScreen({super.key});

  @override
  State<CommandPaletteScreen> createState() => _CommandPaletteScreenState();
}

class _CommandPaletteScreenState extends State<CommandPaletteScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _listScrollCtrl = ScrollController();

  List<Command> _filtered = [];
  int _selectedIndex = 0;
  CommandResult? _lastResult;
  bool _isExecuting = false;
  ProjectContext? _context;

  // Item row height – must match itemExtent in the ListView.builder below.
  static const double _itemExtent = 72.0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshList();
      _detectContext();
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _listScrollCtrl.dispose();
    super.dispose();
  }

  void _refreshList() {
    final svc = context.read<CommandService>();
    final query = _searchCtrl.text;
    final results = svc.search(query);

    // If there is a project context, sort contextually relevant commands first.
    if (_context != null && _context!.projectType != ProjectType.unknown) {
      final relevant = _context!.relevantTags;
      results.sort((a, b) {
        final aRel = a.tags.any(relevant.contains) ? 0 : 1;
        final bRel = b.tags.any(relevant.contains) ? 0 : 1;
        return aRel.compareTo(bRel);
      });
    }

    setState(() {
      _filtered = results;
      _selectedIndex = 0;
    });
  }

  void _onSearchChanged() => _refreshList();

  Future<void> _detectContext() async {
    final platformSvc = context.read<PlatformService>();
    final contextSvc = context.read<ContextService>();
    final workDir = await platformSvc.getActiveAppWorkingDirectory();
    final detected = await contextSvc.detect(path: workDir);
    if (mounted) {
      setState(() => _context = detected);
      _refreshList();
    }
  }

  void _moveSelection(int delta) {
    if (_filtered.isEmpty) return;
    final next = (_selectedIndex + delta).clamp(0, _filtered.length - 1);
    setState(() => _selectedIndex = next);
    _scrollToSelected(next);
  }

  void _scrollToSelected(int index) {
    _listScrollCtrl.animateTo(
      index * _itemExtent,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  Future<void> _runSelected() async {
    if (_filtered.isEmpty) return;
    await _runCommand(_filtered[_selectedIndex]);
  }

  Future<void> _runCommand(Command cmd) async {
    if (_isExecuting) return;
    final platformSvc = context.read<PlatformService>();
    setState(() {
      _isExecuting = true;
      _lastResult = null;
    });
    final result = await platformSvc.executeCommand(cmd.script);
    if (mounted) {
      setState(() {
        _isExecuting = false;
        _lastResult = result;
      });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<CommandService>(
      builder: (context, svc, _) {
        if (!svc.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return KeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            children: [
              _SearchBar(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                context: _context,
                onClear: _clearSearch,
              ),
              if (_filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No commands found.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: _listScrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    itemCount: _filtered.length,
                    itemExtent: _itemExtent,
                    itemBuilder: (ctx, i) => CommandListItem(
                      command: _filtered[i],
                      isSelected: i == _selectedIndex,
                      onTap: () => setState(() => _selectedIndex = i),
                      onRun: () => _runCommand(_filtered[i]),
                    ),
                  ),
                ),
              if (_isExecuting) const LinearProgressIndicator(),
              if (_lastResult != null)
                _ResultPanel(result: _lastResult!),
            ],
          ),
        );
      },
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveSelection(1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveSelection(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _runSelected();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_searchCtrl.text.isNotEmpty) {
          _clearSearch();
        } else {
          // Close palette via platform service.
          context.read<PlatformService>().toggleWindow();
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ProjectContext? context;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.context,
    required this.onClear,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search commands…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: theme.textTheme.bodyLarge,
          ),
          if (context != null &&
              context!.projectType != ProjectType.unknown) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.folder_open,
                    size: 12, color: colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Project: ${context!.projectTypeName}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final CommandResult result;

  const _ResultPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSuccess = result.isSuccess;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: isSuccess
          ? colorScheme.surfaceContainerLow
          : colorScheme.errorContainer.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                size: 14,
                color: isSuccess ? Colors.green : colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                isSuccess
                    ? 'Completed in ${result.duration.inMilliseconds}ms'
                    : 'Failed (exit ${result.exitCode}) in ${result.duration.inMilliseconds}ms',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSuccess ? Colors.green : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (result.stdout.isNotEmpty) ...[
            const SizedBox(height: 4),
            SelectableText(
              result.stdout,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              maxLines: 6,
            ),
          ],
          if (result.stderr.isNotEmpty) ...[
            const SizedBox(height: 4),
            SelectableText(
              result.stderr,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: colorScheme.error,
              ),
              maxLines: 4,
            ),
          ],
        ],
      ),
    );
  }
}
