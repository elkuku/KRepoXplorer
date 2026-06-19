import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart' show AppProvider, DiffMode;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'DIFF',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _DiffModeSelector(),
          const Divider(),
        ],
      ),
    );
  }
}

class _DiffModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diff view mode',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose how diffs are displayed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SegmentedButton<DiffMode>(
            segments: const [
              ButtonSegment(
                value: DiffMode.normal,
                label: Text('Unified'),
                icon: Icon(Icons.view_stream_outlined, size: 16),
              ),
              ButtonSegment(
                value: DiffMode.sideBySide,
                label: Text('Side by side'),
                icon: Icon(Icons.view_column_outlined, size: 16),
              ),
            ],
            selected: {provider.diffMode},
            onSelectionChanged: (val) => provider.setDiffMode(val.first),
            style: ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}
