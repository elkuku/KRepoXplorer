import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../screens/settings_screen.dart';
import 'overview_tab.dart';
import 'commits_tab.dart';
import 'branches_tab.dart';
import 'changes_tab.dart';
import 'diff_view.dart';

class DetailPanel extends StatelessWidget {
  const DetailPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final repo = provider.selectedRepo;

    if (repo == null) {
      return _NoSelection();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(repoName: repo.name, repoPath: repo.path),
        _TabBar(currentTab: provider.detailTab),
        Expanded(child: _TabContent(currentTab: provider.detailTab)),
      ],
    );
  }
}

class _NoSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withAlpha(51),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a repository',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(102),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a repository from the sidebar to view its details',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(77),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatefulWidget {
  final String repoName;
  final String repoPath;

  const _DetailHeader({required this.repoName, required this.repoPath});

  @override
  State<_DetailHeader> createState() => _DetailHeaderState();
}

class _DetailHeaderState extends State<_DetailHeader> {
  Timer? _autoRefreshTimer;
  bool _autoRefresh = false;

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
      if (_autoRefresh) {
        _autoRefreshTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => context.read<AppProvider>().refreshSelectedRepo(),
        );
      } else {
        _autoRefreshTimer?.cancel();
        _autoRefreshTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.source_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.repoName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.repoPath,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(102),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.timer_outlined,
              size: 18,
              color: _autoRefresh ? theme.colorScheme.primary : null,
            ),
            tooltip: _autoRefresh
                ? 'Stop auto-refresh (5s)'
                : 'Start auto-refresh (5s)',
            onPressed: _toggleAutoRefresh,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh',
            onPressed: () => provider.refreshSelectedRepo(),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final String currentTab;
  const _TabBar({required this.currentTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();
    final tabs = [
      ('overview', Icons.info_outline, 'Overview'),
      ('changes', Icons.edit_note, 'Changes'),
      ('commits', Icons.history, 'Commits'),
      ('branches', Icons.call_split, 'Branches'),
      ('diff', Icons.difference_outlined, 'Diff'),
    ];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final (id, icon, label) = tab;
          final isActive = currentTab == id;
          return InkWell(
            onTap: () => provider.setDetailTab(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withAlpha(153),
                      fontWeight: isActive ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final String currentTab;
  const _TabContent({required this.currentTab});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.detailLoadState == LoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.detailLoadState == LoadState.error) {
      return Center(
        child: Text(
          provider.detailError ?? 'Failed to load repository details',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    return switch (currentTab) {
      'overview' => const OverviewTab(),
      'changes' => const ChangesTab(),
      'commits' => const CommitsTab(),
      'branches' => const BranchesTab(),
      'diff' => const DiffView(),
      _ => const SizedBox.shrink(),
    };
  }
}
