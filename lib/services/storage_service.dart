import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _baseFoldersKey = 'base_folders';
  static const _diffModeKey = 'diff_mode';

  Future<List<String>> loadBaseFolders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_baseFoldersKey) ?? [];
  }

  Future<void> saveBaseFolders(List<String> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_baseFoldersKey, folders);
  }

  Future<String> loadDiffMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_diffModeKey) ?? 'normal';
  }

  Future<void> saveDiffMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_diffModeKey, mode);
  }
}
