import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const _key = 'copied_prompts_history';

  /// Save a prompt to history.
  /// Keeps only unique prompts and moves the latest one to the top.
  static Future<void> saveToHistory(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    
    // Remove if already exists so we can move it to the top/latest
    list.remove(prompt);
    list.insert(0, prompt);
    
    // Cap at e.g., 50 items to keep it clean
    if (list.length > 50) {
      list.removeLast();
    }
    
    await prefs.setStringList(_key, list);
  }

  /// Get the list of copied prompts.
  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Clear a specific item from history.
  static Future<void> deleteFromHistory(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(prompt);
    await prefs.setStringList(_key, list);
  }

  /// Clear all history.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
