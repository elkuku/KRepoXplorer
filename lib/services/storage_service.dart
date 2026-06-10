import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _baseFoldersKey = 'base_folders';

  Future<List<String>> loadBaseFolders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_baseFoldersKey) ?? [];
  }

  Future<void> saveBaseFolders(List<String> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_baseFoldersKey, folders);
  }
}
