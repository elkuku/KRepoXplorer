import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/repository.dart';
import '../../providers/app_provider.dart';

class FolderTree extends StatelessWidget {
  const FolderTree({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final folders = provider.baseFolders;

    if (folders.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        return _BaseFolderTile(entry: folders[index]);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: theme.colorScheme.onSurface.withAlpha(77),
          ),
          const SizedBox(height: 12),
          Text(
            'No base folders',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Click + to add a folder containing git repositories',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(102),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BaseFolderTile extends StatelessWidget {
  final BaseFolderEntry entry;
  const _BaseFolderTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => provider.toggleFolderExpanded(entry.path),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Row(
              children: [
                AnimatedRotation(
                  turns: entry.isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.folder, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entry.loadState == LoadState.loading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else
                  _FolderMenu(entry: entry),
              ],
            ),
          ),
        ),
        if (entry.isExpanded) _FolderContent(entry: entry),
        Divider(height: 1, color: theme.dividerColor),
      ],
    );
  }
}

class _FolderContent extends StatelessWidget {
  final BaseFolderEntry entry;
  const _FolderContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.loadState == LoadState.error) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Error: ${entry.error}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 11,
          ),
        ),
      );
    }
    if (entry.repositories.isEmpty && entry.loadState == LoadState.loaded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 8, 8),
        child: Text(
          'No repositories found',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
          ),
        ),
      );
    }
    return Column(
      children: entry.repositories.map((r) => _RepoTile(repo: r)).toList(),
    );
  }
}

class _RepoTile extends StatelessWidget {
  final GitRepository repo;
  const _RepoTile({required this.repo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    final isSelected = provider.selectedRepo?.path == repo.path;

    return InkWell(
      onTap: () => provider.selectRepository(repo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 38,
        padding: const EdgeInsets.only(left: 32, right: 8),
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              Icons.source_outlined,
              size: 14,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface.withAlpha(153),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                repo.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _RepoBadges(repo: repo, isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _RepoBadges extends StatelessWidget {
  final GitRepository repo;
  final bool isSelected;
  const _RepoBadges({required this.repo, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.onPrimaryContainer.withAlpha(179)
        : theme.colorScheme.onSurface.withAlpha(102);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (repo.hasUncommittedChanges)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
        if (repo.aheadCount > 0)
          Text(
            '↑${repo.aheadCount}',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
          ),
        if (repo.behindCount > 0)
          Text(
            '↓${repo.behindCount}',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.secondary),
          ),
        if (repo.currentBranch != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.call_split, size: 10, color: color),
          const SizedBox(width: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              repo.currentBranch!,
              style: TextStyle(fontSize: 10, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _FolderMenu extends StatelessWidget {
  final BaseFolderEntry entry;
  const _FolderMenu({required this.entry});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return PopupMenuButton<String>(
      iconSize: 14,
      padding: EdgeInsets.zero,
      tooltip: 'Folder options',
      onSelected: (value) {
        switch (value) {
          case 'refresh':
            provider.refreshFolder(entry.path);
          case 'remove':
            provider.removeBaseFolder(entry.path);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 16),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 16),
              SizedBox(width: 8),
              Text('Remove'),
            ],
          ),
        ),
      ],
    );
  }
}
