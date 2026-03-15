import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/dock_window_service.dart';

/// Dock settings panel.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Icon(Icons.tune, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text('Settings',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _Section(
                title: 'Dock',
                children: [
                  _SettingRow(
                    icon: Icons.dock,
                    title: 'Re-anchor to screen bottom',
                    subtitle: 'Move dock back to bottom-centre of the primary screen',
                    trailing: FilledButton.tonal(
                      onPressed: () =>
                          context.read<DockWindowService>().reanchor(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Re-anchor', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'About',
                children: [
                  _SettingRow(
                    icon: Icons.info_outline,
                    title: 'Snapd Developer Dock',
                    subtitle: 'Version 1.0.0 · Flutter + Swift · macOS',
                  ),
                  _SettingRow(
                    icon: Icons.keyboard_outlined,
                    title: 'Global hotkey',
                    subtitle: '⌘Space  — Toggle dock visibility',
                  ),
                  _SettingRow(
                    icon: Icons.escape_outlined,
                    title: 'Keyboard shortcuts',
                    subtitle: 'Esc — Close active panel',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'AI Providers',
                children: [
                  _SettingRow(
                    icon: Icons.hub_outlined,
                    title: 'Supported providers',
                    subtitle:
                        'OpenAI · Anthropic · Google Gemini · Ollama · Custom OpenAI-compatible endpoints',
                  ),
                  _SettingRow(
                    icon: Icons.computer_outlined,
                    title: 'Local AI with Ollama',
                    subtitle:
                        'Run Ollama at http://localhost:11434 — no API key required',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 16, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodySmall),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ))
          : null,
      trailing: trailing,
    );
  }
}
