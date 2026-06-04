import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_prompt_ids';

  // Memory cache of loaded prompts
  static final List<Map<String, dynamic>> _promptsCache = [];

  static final ValueNotifier<Set<String>> favoritesNotifier = ValueNotifier<Set<String>>({});

  /// Add/update prompts in the memory cache
  static void cachePrompts(List<Map<String, dynamic>> prompts) {
    for (final prompt in prompts) {
      if (prompt['docId'] == null) continue;
      final index = _promptsCache.indexWhere((p) => p['docId'] == prompt['docId']);
      if (index != -1) {
        _promptsCache[index] = prompt;
      } else {
        _promptsCache.add(prompt);
      }
    }
  }

  /// Get cached favorites matching the given IDs
  static List<Map<String, dynamic>> getCachedFavorites(Set<String> favIds) {
    return _promptsCache.where((p) => favIds.contains(p['docId'])).toList();
  }

  /// Get all cached prompts from the memory cache
  static List<Map<String, dynamic>> getCachedPrompts() {
    return _promptsCache;
  }

  /// Get the user's favorite IDs.
  static Future<Set<String>> getFavorites({bool fetchFromFirestore = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.toSet();
    if (favoritesNotifier.value.length != set.length || !favoritesNotifier.value.containsAll(set)) {
      favoritesNotifier.value = set;
    }
    return set;
  }

  /// Toggles a favorite item.
  /// Updates local SharedPreferences instantly so the UI is responsive.
  static Future<void> toggleFavorite(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.toSet();
    
    final isAdding = !set.contains(docId);

    // Update local cache
    if (isAdding) {
      set.add(docId);
    } else {
      set.remove(docId);
    }
    await prefs.setStringList(_key, set.toList());
    favoritesNotifier.value = set;
  }

  /// Check if a prompt is in the favorites list.
  static Future<bool> isFavorite(String docId) async {
    final favorites = await getFavorites();
    return favorites.contains(docId);
  }
}
