class GitRepository {
  final String path;
  final String name;
  String? currentBranch;
  bool hasUncommittedChanges;
  int aheadCount;
  int behindCount;
  String? remoteUrl;

  GitRepository({
    required this.path,
    required this.name,
    this.currentBranch,
    this.hasUncommittedChanges = false,
    this.aheadCount = 0,
    this.behindCount = 0,
    this.remoteUrl,
  });

  String get statusSummary {
    final parts = <String>[];
    if (hasUncommittedChanges) parts.add('modified');
    if (aheadCount > 0) parts.add('↑$aheadCount');
    if (behindCount > 0) parts.add('↓$behindCount');
    return parts.isEmpty ? 'clean' : parts.join(' ');
  }
}

class GitCommit {
  final String hash;
  final String shortHash;
  final String message;
  final String author;
  final DateTime date;

  const GitCommit({
    required this.hash,
    required this.shortHash,
    required this.message,
    required this.author,
    required this.date,
  });
}

class GitStatusFile {
  final String path;
  final String status;

  const GitStatusFile({required this.path, required this.status});

  String get statusLabel {
    switch (status) {
      case 'M':
        return 'Modified';
      case 'A':
        return 'Added';
      case 'D':
        return 'Deleted';
      case 'R':
        return 'Renamed';
      case '?':
        return 'Untracked';
      default:
        return status;
    }
  }
}

class GitBranch {
  final String name;
  final bool isCurrent;
  final bool isRemote;

  const GitBranch({
    required this.name,
    required this.isCurrent,
    this.isRemote = false,
  });
}
