import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/repository.dart';
import '../../providers/app_provider.dart';

class BranchesTab extends StatelessWidget {
  const BranchesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = context.watch<AppProvider>().branches;
    final local = branches.where((b) => !b.isRemote).toList();
    final remote = branches.where((b) => b.isRemote).toList();

    if (branches.isEmpty) {
      return const Center(child: Text('No branches found'));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (local.isNotEmpty) ...[
          _SectionHeader(title: 'Local Branches', count: local.length),
          const SizedBox(height: 4),
          ...local.map((b) => _BranchTile(branch: b)),
        ],
        if (remote.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: 'Remote Branches', count: remote.length),
          const SizedBox(height: 4),
          ...remote.map((b) => _BranchTile(branch: b)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final GitBranch branch;
  const _BranchTile({required this.branch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: branch.isCurrent
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: branch.isCurrent
              ? theme.colorScheme.primary.withAlpha(77)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            branch.isRemote ? Icons.cloud_outlined : Icons.call_split,
            size: 14,
            color: branch.isCurrent
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface.withAlpha(153),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              branch.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: branch.isCurrent ? FontWeight.w600 : null,
                color: branch.isCurrent
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (branch.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'current',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
