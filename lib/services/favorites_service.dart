import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_prompt_ids';

  /// Get the user's favorite IDs.
  static Future<Set<String>> getFavorites({bool fetchFromFirestore = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
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
  }

  /// Check if a prompt is in the favorites list.
  static Future<bool> isFavorite(String docId) async {
    final favorites = await getFavorites();
    return favorites.contains(docId);
  }
}
