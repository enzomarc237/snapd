import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/command_result.dart';
import '../models/project_context.dart';
import '../services/context_service.dart';
import '../services/platform_service.dart';

/// Quick-action developer tools panel.
///
/// Displays categorised shortcut buttons for common dev commands.
/// Tapping a button executes the command via the platform shell.
class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  CommandResult? _lastResult;
  String? _runningCommand;
  ProjectContext? _ctx;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectContext());
  }

  Future<void> _detectContext() async {
    final contextSvc = context.read<ContextService>();
    final platformSvc = context.read<PlatformService>();
    final workDir = await platformSvc.getActiveAppWorkingDirectory();
    final detected = await contextSvc.detect(path: workDir);
    if (mounted) setState(() => _ctx = detected);
  }

  Future<void> _run(String label, String script) async {
    if (_runningCommand != null) return;
    final platformSvc = context.read<PlatformService>();
    setState(() {
      _runningCommand = label;
      _lastResult = null;
    });
    final result = await platformSvc.executeCommand(script);
    if (mounted) {
      setState(() {
        _runningCommand = null;
        _lastResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Icon(Icons.build_outlined,
                  size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text('Dev Tools',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_ctx != null &&
                  _ctx!.projectType != ProjectType.unknown)
                Chip(
                  label: Text(_ctx!.projectTypeName,
                      style: const TextStyle(fontSize: 10)),
                  avatar: const Icon(Icons.folder_open, size: 12),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh, size: 14),
                onPressed: _detectContext,
                tooltip: 'Refresh context',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ToolGroup(
                  title: 'Git',
                  color: const Color(0xFFF97316),
                  commands: [
                    _ToolCmd('Status', 'git status'),
                    _ToolCmd('Pull', 'git pull'),
                    _ToolCmd('Push', 'git push'),
                    _ToolCmd('Fetch', 'git fetch'),
                    _ToolCmd('Log', 'git log --oneline -20'),
                    _ToolCmd('Stash', 'git stash'),
                    _ToolCmd('Branches', 'git branch -a'),
                  ],
                  running: _runningCommand,
                  onRun: _run,
                ),
                const SizedBox(height: 10),
                _ToolGroup(
                  title: 'Node / npm',
                  color: const Color(0xFF22C55E),
                  commands: [
                    _ToolCmd('Install', 'npm install'),
                    _ToolCmd('Test', 'npm test'),
                    _ToolCmd('Build', 'npm run build'),
                    _ToolCmd('Start', 'npm start'),
                    _ToolCmd('Audit', 'npm audit'),
                    _ToolCmd('Outdated', 'npm outdated'),
                  ],
                  running: _runningCommand,
                  onRun: _run,
                ),
                const SizedBox(height: 10),
                _ToolGroup(
                  title: 'Python',
                  color: const Color(0xFF3B82F6),
                  commands: [
                    _ToolCmd('Install reqs', 'pip install -r requirements.txt'),
                    _ToolCmd('Run tests', 'python -m pytest'),
                    _ToolCmd('Format', 'black .'),
                    _ToolCmd('Lint', 'ruff check .'),
                    _ToolCmd('Type check', 'mypy .'),
                  ],
                  running: _runningCommand,
                  onRun: _run,
                ),
                const SizedBox(height: 10),
                _ToolGroup(
                  title: 'Go',
                  color: const Color(0xFF06B6D4),
                  commands: [
                    _ToolCmd('Build', 'go build ./...'),
                    _ToolCmd('Test', 'go test ./...'),
                    _ToolCmd('Run', 'go run .'),
                    _ToolCmd('Tidy', 'go mod tidy'),
                    _ToolCmd('Vet', 'go vet ./...'),
                    _ToolCmd('Fmt', 'gofmt -l .'),
                  ],
                  running: _runningCommand,
                  onRun: _run,
                ),
                const SizedBox(height: 10),
                _ToolGroup(
                  title: 'Docker',
                  color: const Color(0xFF2563EB),
                  commands: [
                    _ToolCmd('PS', 'docker ps'),
                    _ToolCmd('Images', 'docker images'),
                    _ToolCmd('Build', 'docker build .'),
                    _ToolCmd('Compose Up', 'docker compose up -d'),
                    _ToolCmd('Compose Down', 'docker compose down'),
                    _ToolCmd('Prune', 'docker system prune -f'),
                  ],
                  running: _runningCommand,
                  onRun: _run,
                ),
              ],
            ),
          ),
        ),
        if (_runningCommand != null) const LinearProgressIndicator(minHeight: 2),
        if (_lastResult != null) _ResultBanner(result: _lastResult!),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ToolCmd {
  final String label;
  final String script;
  const _ToolCmd(this.label, this.script);
}

class _ToolGroup extends StatelessWidget {
  final String title;
  final Color color;
  final List<_ToolCmd> commands;
  final String? running;
  final void Function(String label, String script) onRun;

  const _ToolGroup({
    required this.title,
    required this.color,
    required this.commands,
    required this.running,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Text(title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                )),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: commands
              .map((cmd) => _ToolButton(
                    label: cmd.label,
                    isRunning: running == cmd.label,
                    isDisabled: running != null,
                    accentColor: color,
                    onTap: () => onRun(cmd.label, cmd.script),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String label;
  final bool isRunning;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _ToolButton({
    required this.label,
    required this.isRunning,
    required this.isDisabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isRunning
              ? accentColor.withOpacity(0.2)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRunning
                ? accentColor
                : colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: isRunning
            ? SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: accentColor,
                  minHeight: 2,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDisabled
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.onSurface,
                ),
              ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final CommandResult result;
  const _ResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ok = result.isSuccess;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: ok
          ? Colors.green.withOpacity(0.08)
          : colorScheme.errorContainer.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
                  size: 12, color: ok ? Colors.green : colorScheme.error),
              const SizedBox(width: 4),
              Text(
                ok
                    ? '✓ ${result.duration.inMilliseconds}ms'
                    : '✗ exit ${result.exitCode}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ok ? Colors.green : colorScheme.error,
                ),
              ),
            ],
          ),
          if (result.stdout.isNotEmpty)
            SelectableText(
              result.stdout,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              maxLines: 4,
            ),
          if (result.stderr.isNotEmpty)
            SelectableText(
              result.stderr,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: colorScheme.error),
              maxLines: 3,
            ),
        ],
      ),
    );
  }
}
