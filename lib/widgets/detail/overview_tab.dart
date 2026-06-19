import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/repository.dart';
import '../../providers/app_provider.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final repo = provider.selectedRepo;
    if (repo == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Repository Info'),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.folder_outlined,
                label: 'Path',
                value: repo.path,
              ),
              _InfoRow(
                icon: Icons.call_split,
                label: 'Branch',
                value: repo.currentBranch ?? 'unknown',
                valueColor: theme.colorScheme.primary,
              ),
              _InfoRow(
                icon: Icons.cloud_outlined,
                label: 'Remote',
                value: repo.remoteUrl ?? 'No remote',
              ),
              _InfoRow(
                icon: Icons.circle,
                label: 'Status',
                value: repo.statusSummary,
                valueColor: repo.hasUncommittedChanges
                    ? theme.colorScheme.error
                    : Colors.green,
              ),
              if (repo.aheadCount > 0 || repo.behindCount > 0)
                _InfoRow(
                  icon: Icons.sync_alt,
                  label: 'Sync',
                  value: [
                    if (repo.aheadCount > 0) '${repo.aheadCount} ahead',
                    if (repo.behindCount > 0) '${repo.behindCount} behind',
                  ].join(', '),
                ),
            ],
          ),
          if (provider.statusFiles.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(
              title: 'Changed Files (${provider.statusFiles.length})',
            ),
            const SizedBox(height: 8),
            _InfoCard(
              children: provider.statusFiles
                  .take(10)
                  .map((f) => _FileStatusRow(file: f))
                  .toList(),
            ),
            if (provider.statusFiles.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text(
                  '+ ${provider.statusFiles.length - 10} more files',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(102),
                  ),
                ),
              ),
          ],
          if (provider.commits.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(title: 'Recent Commits'),
            const SizedBox(height: 8),
            _InfoCard(
              children: provider.commits
                  .take(5)
                  .map((c) => _CommitRow(commit: c))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    Divider(height: 1, color: theme.dividerColor),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withAlpha(102),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontFamily: label == 'Path' ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileStatusRow extends StatelessWidget {
  final GitStatusFile file;
  const _FileStatusRow({required this.file});

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    return switch (file.status) {
      'M' => Colors.orange,
      'A' => Colors.green,
      'D' => theme.colorScheme.error,
      '?' => theme.colorScheme.onSurface.withAlpha(153),
      _ => theme.colorScheme.onSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            alignment: Alignment.center,
            child: Text(
              file.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _statusColor(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.path,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitRow extends StatelessWidget {
  final GitCommit commit;
  const _CommitRow({required this.commit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(commit.date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              commit.shortHash,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit.message,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${commit.author} · $dateStr',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(102),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
