import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../services/git_service.dart';
import '../services/storage_service.dart';

enum LoadState { idle, loading, loaded, error }

enum DiffMode { normal, sideBySide }

enum DetailTab { overview, changes, commits, branches, diff }

class BaseFolderEntry {
  final String path;
  bool isExpanded;
  LoadState loadState;
  List<GitRepository> repositories;
  String? error;

  BaseFolderEntry({
    required this.path,
    this.isExpanded = true,
    this.loadState = LoadState.idle,
    this.repositories = const [],
    this.error,
  });

  String get name => path.split('/').last;
}

class AppProvider extends ChangeNotifier {
  final GitService _git = GitService();
  final StorageService _storage = StorageService();

  final List<BaseFolderEntry> _baseFolders = [];
  GitRepository? _selectedRepo;
  DetailTab _detailTab = DetailTab.overview;
  GitStatusFile? _selectedStatusFile;

  // Detail panel data
  List<GitCommit> commits = [];
  List<GitStatusFile> statusFiles = [];
  List<GitBranch> branches = [];
  String? diffContent;
  LoadState detailLoadState = LoadState.idle;
  String? detailError;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  DiffMode _diffMode = DiffMode.normal;
  DiffMode get diffMode => _diffMode;

  List<BaseFolderEntry> get baseFolders => List.unmodifiable(_baseFolders);
  GitRepository? get selectedRepo => _selectedRepo;
  DetailTab get detailTab => _detailTab;
  GitStatusFile? get selectedStatusFile => _selectedStatusFile;

  Future<void> initialize() async {
    final saved = await _storage.loadBaseFolders();
    for (final path in saved) {
      _baseFolders.add(BaseFolderEntry(path: path));
    }
    _diffMode = await _storage.loadDiffMode();
    _initialized = true;
    notifyListeners();
    for (final folder in _baseFolders) {
      _loadFolder(folder);
    }
  }

  Future<void> setDiffMode(DiffMode mode) async {
    _diffMode = mode;
    await _storage.saveDiffMode(mode);
    notifyListeners();
  }

  Future<void> addBaseFolder(String path) async {
    if (_baseFolders.any((f) => f.path == path)) return;
    final entry = BaseFolderEntry(path: path);
    _baseFolders.add(entry);
    await _storage.saveBaseFolders(_baseFolders.map((f) => f.path).toList());
    notifyListeners();
    await _loadFolder(entry);
  }

  Future<void> removeBaseFolder(String path) async {
    _baseFolders.removeWhere((f) => f.path == path);
    if (_selectedRepo?.path.startsWith(path) == true) {
      _selectedRepo = null;
      commits = [];
      statusFiles = [];
      branches = [];
      diffContent = null;
    }
    await _storage.saveBaseFolders(_baseFolders.map((f) => f.path).toList());
    notifyListeners();
  }

  Future<void> _loadFolder(BaseFolderEntry entry) async {
    entry.loadState = LoadState.loading;
    entry.repositories = [];
    notifyListeners();
    try {
      final repos = await _git.findRepositories(entry.path);
      await Future.wait(repos.map(_git.loadRepositoryDetails));
      repos.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      entry.repositories = repos;
      entry.loadState = LoadState.loaded;
    } catch (e) {
      entry.error = e.toString();
      entry.loadState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> refreshFolder(String path) async {
    final entry = _baseFolders.firstWhere((f) => f.path == path);
    await _loadFolder(entry);
  }

  void toggleFolderExpanded(String path) {
    final entry = _baseFolders.firstWhere((f) => f.path == path);
    entry.isExpanded = !entry.isExpanded;
    notifyListeners();
  }

  Future<void> selectRepository(GitRepository repo) async {
    _selectedRepo = repo;
    _selectedStatusFile = null;
    diffContent = null;
    detailLoadState = LoadState.loading;
    notifyListeners();
    await _loadRepoDetails(repo);
  }

  Future<void> _loadRepoDetails(GitRepository repo) async {
    try {
      final results = await Future.wait([
        _git.getRecentCommits(repo.path),
        _git.getStatus(repo.path),
        _git.getBranches(repo.path),
      ]);
      commits = results[0] as List<GitCommit>;
      statusFiles = results[1] as List<GitStatusFile>;
      branches = results[2] as List<GitBranch>;
      detailLoadState = LoadState.loaded;
      detailError = null;
    } catch (e) {
      detailLoadState = LoadState.error;
      detailError = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshSelectedRepo() async {
    if (_selectedRepo == null) return;
    detailLoadState = LoadState.loading;
    notifyListeners();
    await _git.loadRepositoryDetails(_selectedRepo!);
    await _loadRepoDetails(_selectedRepo!);
  }

  void setDetailTab(DetailTab tab) {
    _detailTab = tab;
    _selectedStatusFile = null;
    diffContent = null;
    notifyListeners();
  }

  Future<void> selectStatusFile(GitStatusFile file) async {
    _selectedStatusFile = file;
    diffContent = null;
    notifyListeners();
    if (_selectedRepo != null) {
      diffContent =
          await _git.getFileDiff(_selectedRepo!.path, file.path) ?? '';
      notifyListeners();
    }
  }

  Future<void> loadFullDiff() async {
    if (_selectedRepo == null) return;
    diffContent = await _git.getDiff(_selectedRepo!.path);
    notifyListeners();
  }
}
