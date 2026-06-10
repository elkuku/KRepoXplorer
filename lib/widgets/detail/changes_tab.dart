import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/repository.dart';
import '../../providers/app_provider.dart';
import 'diff_view.dart';

class ChangesTab extends StatelessWidget {
  const ChangesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final files = provider.statusFiles;

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            const Text('Working tree clean'),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 260,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: Text(
                  '${files.length} changed file${files.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) =>
                      _FileListTile(file: files[index]),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(child: _FileDiffPanel()),
      ],
    );
  }
}

class _FileListTile extends StatelessWidget {
  final GitStatusFile file;
  const _FileListTile({required this.file});

  Color _statusColor(BuildContext context) {
    return switch (file.status) {
      'M' => Colors.orange,
      'A' => Colors.green,
      'D' => Theme.of(context).colorScheme.error,
      '?' => Theme.of(context).colorScheme.onSurface.withAlpha(153),
      _ => Theme.of(context).colorScheme.onSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    final isSelected = provider.selectedStatusFile?.path == file.path;

    return InkWell(
      onTap: () => provider.selectStatusFile(file),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected ? theme.colorScheme.primaryContainer : null,
        child: Row(
          children: [
            Text(
              file.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _statusColor(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.path.split('/').last,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (file.path.contains('/'))
                    Text(
                      file.path.split('/').reversed.skip(1).toList().reversed.join('/'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(102),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileDiffPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selectedFile = provider.selectedStatusFile;

    if (selectedFile == null) {
      return const Center(
        child: Text('Select a file to view its diff'),
      );
    }

    if (provider.diffContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return DiffView(content: provider.diffContent);
  }
}
