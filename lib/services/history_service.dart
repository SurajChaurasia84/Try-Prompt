import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CopiedPrompt {
  final String prompt;
  final String imageUrl;
  final DateTime copiedAt;

  CopiedPrompt({
    required this.prompt,
    required this.imageUrl,
    required this.copiedAt,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'imageUrl': imageUrl,
        'copiedAt': copiedAt.toIso8601String(),
      };

  factory CopiedPrompt.fromJson(Map<String, dynamic> json) => CopiedPrompt(
        prompt: json['prompt'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        copiedAt: json['copiedAt'] != null
            ? DateTime.parse(json['copiedAt'] as String)
            : DateTime.now(),
      );

  factory CopiedPrompt.fromRawString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return CopiedPrompt.fromJson(decoded);
      }
    } catch (_) {}
    // Fallback for migration from raw string history format
    return CopiedPrompt(
      prompt: raw,
      imageUrl: '',
      copiedAt: DateTime.now(),
    );
  }
}

class HistoryService {
  static const _key = 'copied_prompts_history';

  /// Save a prompt to history with optional image.
  /// Records every copy action chronologically, preventing immediate consecutive duplicates.
  static Future<void> saveToHistory(String prompt, {String imageUrl = ''}) async {
    if (prompt.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    final newEntry = CopiedPrompt(
      prompt: prompt,
      imageUrl: imageUrl,
      copiedAt: DateTime.now(),
    );

    // Get the first item's prompt text to check for consecutive duplicates
    String? firstPromptText;
    if (list.isNotEmpty) {
      firstPromptText = CopiedPrompt.fromRawString(list.first).prompt;
    }

    // Allow duplicates but prevent immediate consecutive identical prompt text entries
    if (list.isEmpty || firstPromptText != prompt) {
      list.insert(0, jsonEncode(newEntry.toJson()));
    }

    // Cap at 50 items to keep it clean
    if (list.length > 50) {
      list.removeLast();
    }

    await prefs.setStringList(_key, list);
  }

  /// Get the list of copied prompts.
  static Future<List<CopiedPrompt>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((item) => CopiedPrompt.fromRawString(item)).toList();
  }

  /// Clear a specific item from history.
  static Future<void> deleteFromHistory(CopiedPrompt entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    final toRemove = <String>[];
    for (final raw in list) {
      final parsed = CopiedPrompt.fromRawString(raw);
      // Compare prompt text and exact copiedAt timestamp to identify the entry
      if (parsed.prompt == entry.prompt &&
          parsed.copiedAt.millisecondsSinceEpoch == entry.copiedAt.millisecondsSinceEpoch) {
        toRemove.add(raw);
      }
    }

    for (final item in toRemove) {
      list.remove(item);
    }
    await prefs.setStringList(_key, list);
  }

  /// Clear all history.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
