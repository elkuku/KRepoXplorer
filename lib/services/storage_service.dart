import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';

class StorageService {
  static const _baseFoldersKey = 'base_folders';
  static const _diffModeKey = 'diff_mode';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<String>> loadBaseFolders() async {
    final prefs = await _instance;
    return prefs.getStringList(_baseFoldersKey) ?? [];
  }

  Future<void> saveBaseFolders(List<String> folders) async {
    final prefs = await _instance;
    await prefs.setStringList(_baseFoldersKey, folders);
  }

  Future<DiffMode> loadDiffMode() async {
    final prefs = await _instance;
    final raw = prefs.getString(_diffModeKey) ?? '';
    return DiffMode.values.where((e) => e.name == raw).firstOrNull ??
        DiffMode.normal;
  }

  Future<void> saveDiffMode(DiffMode mode) async {
    final prefs = await _instance;
    await prefs.setString(_diffModeKey, mode.name);
  }
}
