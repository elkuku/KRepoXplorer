import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/repository.dart';

class GitService {
  Future<List<GitRepository>> findRepositories(String basePath) async {
    final repos = <GitRepository>[];
    await _scanDirectory(Directory(basePath), repos, depth: 0);
    return repos;
  }

  Future<void> _scanDirectory(
    Directory dir,
    List<GitRepository> repos, {
    required int depth,
  }) async {
    if (depth > 4) return;
    try {
      final gitDir = Directory(p.join(dir.path, '.git'));
      if (await gitDir.exists()) {
        repos.add(GitRepository(path: dir.path, name: p.basename(dir.path)));
        return; // don't recurse into git repos
      }
      final entries = await dir.list(followLinks: false).toList();
      for (final entry in entries) {
        if (entry is Directory) {
          final name = p.basename(entry.path);
          if (!name.startsWith('.') && name != 'node_modules') {
            await _scanDirectory(entry, repos, depth: depth + 1);
          }
        }
      }
    } catch (_) {}
  }

  Future<String?> getCurrentBranch(String repoPath) async {
    final result = await _run(repoPath, ['rev-parse', '--abbrev-ref', 'HEAD']);
    return result?.trim();
  }

  Future<bool> hasUncommittedChanges(String repoPath) async {
    final result = await _run(repoPath, ['status', '--porcelain']);
    return result != null && result.trim().isNotEmpty;
  }

  Future<String?> getRemoteUrl(String repoPath) async {
    final result = await _run(repoPath, ['remote', 'get-url', 'origin']);
    return result?.trim().isEmpty == true ? null : result?.trim();
  }

  Future<({int ahead, int behind})> getAheadBehind(String repoPath) async {
    final result = await _run(repoPath, [
      'rev-list',
      '--left-right',
      '--count',
      '@{upstream}...HEAD',
    ]);
    if (result == null) return (ahead: 0, behind: 0);
    final parts = result.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return (ahead: 0, behind: 0);
    return (
      ahead: int.tryParse(parts[1]) ?? 0,
      behind: int.tryParse(parts[0]) ?? 0,
    );
  }

  Future<List<GitCommit>> getRecentCommits(
    String repoPath, {
    int limit = 20,
  }) async {
    final result = await _run(repoPath, [
      'log',
      '--format=%H%x1f%h%x1f%s%x1f%an%x1f%aI',
      '-n',
      '$limit',
    ]);
    if (result == null || result.trim().isEmpty) return [];
    return result
        .trim()
        .split('\n')
        .where((l) => l.isNotEmpty)
        .map((line) {
          final parts = line.split('\x1f');
          if (parts.length < 5) return null;
          return GitCommit(
            hash: parts[0],
            shortHash: parts[1],
            message: parts[2],
            author: parts[3],
            date: DateTime.tryParse(parts[4]) ?? DateTime.now(),
          );
        })
        .whereType<GitCommit>()
        .toList();
  }

  Future<List<GitStatusFile>> getStatus(String repoPath) async {
    final result = await _run(repoPath, ['status', '--porcelain']);
    if (result == null || result.trim().isEmpty) return [];
    return result
        .trim()
        .split('\n')
        .where((l) => l.isNotEmpty)
        .map((line) {
          final xy = line.substring(0, 2).trim();
          final path = line.substring(3).trim();
          final status = xy.isEmpty ? '?' : xy[0];
          return GitStatusFile(path: path, status: status);
        })
        .toList();
  }

  Future<List<GitBranch>> getBranches(String repoPath) async {
    final result = await _run(repoPath, ['branch', '-a', '--format=%(refname:short) %(HEAD)']);
    if (result == null || result.trim().isEmpty) return [];
    return result
        .trim()
        .split('\n')
        .where((l) => l.isNotEmpty)
        .map((line) {
          final isCurrent = line.endsWith(' *');
          final name = isCurrent ? line.substring(0, line.length - 2).trim() : line.trim();
          return GitBranch(
            name: name,
            isCurrent: isCurrent,
            isRemote: name.startsWith('remotes/'),
          );
        })
        .toList();
  }

  Future<String?> getDiff(String repoPath, {String? filePath}) async {
    final args = ['diff', 'HEAD'];
    if (filePath != null) args.add(filePath);
    return _run(repoPath, args);
  }

  Future<String?> getFileDiff(String repoPath, String filePath) async {
    var result = await _run(repoPath, ['diff', 'HEAD', '--', filePath]);
    if (result == null || result.trim().isEmpty) {
      result = await _run(repoPath, ['diff', '--cached', '--', filePath]);
    }
    if (result == null || result.trim().isEmpty) {
      result = await _run(repoPath, ['show', 'HEAD:$filePath']);
    }
    if (result == null || result.trim().isEmpty) {
      result = await _runUntrackedDiff(repoPath, filePath);
    }
    return result;
  }

  // git diff --no-index exits with 1 when differences exist, so _run discards it
  Future<String?> _runUntrackedDiff(String repoPath, String filePath) async {
    try {
      final result = await Process.run(
        'git',
        ['diff', '--no-index', '/dev/null', filePath],
        workingDirectory: repoPath,
        runInShell: false,
      );
      final output = result.stdout as String;
      return output.trim().isNotEmpty ? output : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRepositoryDetails(GitRepository repo) async {
    repo.currentBranch = await getCurrentBranch(repo.path);
    repo.hasUncommittedChanges = await hasUncommittedChanges(repo.path);
    repo.remoteUrl = await getRemoteUrl(repo.path);
    final counts = await getAheadBehind(repo.path);
    repo.aheadCount = counts.ahead;
    repo.behindCount = counts.behind;
  }

  Future<String?> _run(String repoPath, List<String> args) async {
    try {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: repoPath,
        runInShell: false,
      );
      if (result.exitCode == 0) return result.stdout as String;
      return null;
    } catch (_) {
      return null;
    }
  }
}
