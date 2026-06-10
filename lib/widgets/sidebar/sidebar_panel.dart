import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'folder_tree.dart';

class SidebarPanel extends StatelessWidget {
  const SidebarPanel({super.key});

  Future<void> _pickFolder(BuildContext context) async {
    final path = await getDirectoryPath(confirmButtonText: 'Select Base Folder');
    if (path != null && context.mounted) {
      context.read<AppProvider>().addBaseFolder(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Repositories',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Add base folder',
                onPressed: () => _pickFolder(context),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Expanded(child: FolderTree()),
      ],
    );
  }
}
