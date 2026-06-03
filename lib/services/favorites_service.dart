import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FavoritesService {
  static const _key = 'favorite_prompt_ids';

  /// Get the user's favorite IDs.
  /// If [fetchFromFirestore] is true and a user is signed in, it fetches the list from Firestore
  /// and updates the local cache first.
  static Future<Set<String>> getFavorites({bool fetchFromFirestore = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (fetchFromFirestore) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .get();
          
          final firestoreIds = snapshot.docs.map((doc) => doc.id).toList();
          await prefs.setStringList(_key, firestoreIds);
          return firestoreIds.toSet();
        } catch (e) {
          debugPrint("Failed to fetch favorites from Firestore: $e");
        }
      }
    }

    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  /// Toggles a favorite item.
  /// Updates local SharedPreferences instantly so the UI is responsive,
  /// and updates Firestore in the background.
  static Future<void> toggleFavorite(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.toSet();
    
    final user = FirebaseAuth.instance.currentUser;
    final isAdding = !set.contains(docId);

    // Update local cache
    if (isAdding) {
      set.add(docId);
    } else {
      set.remove(docId);
    }
    await prefs.setStringList(_key, set.toList());

    // Sync with Firestore in the background (fire-and-forget so UI toggles instantly)
    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(docId);
      
      final Future<void> syncFuture = isAdding
          ? docRef.set({
              'addedAt': FieldValue.serverTimestamp(),
            })
          : docRef.delete();

      syncFuture.catchError((e) {
        debugPrint("Failed to sync favorite toggle to Firestore: $e");
      });
    }
  }

  /// Check if a prompt is in the favorites list.
  static Future<bool> isFavorite(String docId) async {
    final favorites = await getFavorites();
    return favorites.contains(docId);
  }
}
