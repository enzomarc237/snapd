import 'package:flutter/material.dart';

import '../models/command.dart';

/// A single row in the command list showing name, description, tags, and a
/// run button.
class CommandListItem extends StatelessWidget {
  final Command command;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRun;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommandListItem({
    super.key,
    required this.command,
    required this.isSelected,
    required this.onTap,
    required this.onRun,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      command.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (command.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        command.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (command.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: command.tags
                            .take(4)
                            .map(
                              (tag) => _TagChip(
                                label: tag,
                                isSelected: isSelected,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action buttons – only visible on selection or hover.
              if (isSelected) ...[
                if (onEdit != null)
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onPressed: onEdit!,
                    color: colorScheme.onPrimaryContainer,
                  ),
                if (onDelete != null)
                  _IconBtn(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    onPressed: onDelete!,
                    color: colorScheme.error,
                  ),
                _RunButton(onRun: onRun),
              ] else
                _RunButton(onRun: onRun),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TagChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.2)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        color: color,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  final VoidCallback onRun;

  const _RunButton({required this.onRun});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Run (↵)',
      child: FilledButton.tonal(
        onPressed: onRun,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: const Size(0, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Run', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}
