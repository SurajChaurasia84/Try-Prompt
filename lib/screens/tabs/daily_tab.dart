import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/favorites_service.dart';
import '../prompt_view_screen.dart';
import 'home_tab.dart';

class DailyTab extends StatefulWidget {
  final String searchQuery;
  const DailyTab({super.key, this.searchQuery = ''});

  @override
  State<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<DailyTab> {
  List<Map<String, dynamic>> _allDocs = [];
  Set<String> _favorites = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    FavoritesService.favoritesNotifier.addListener(_onFavoritesChanged);
    _loadAllPrompts();
    _loadFavorites();
  }

  @override
  void dispose() {
    FavoritesService.favoritesNotifier.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {
        _favorites = FavoritesService.favoritesNotifier.value;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _favorites = favs;
      });
    }
  }

  Future<void> _toggleFavorite(String docId) async {
    await FavoritesService.toggleFavorite(docId);
  }

  Future<void> _loadAllPrompts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // 1. Try to load from cached prompts first
      final allCached = FavoritesService.getCachedPrompts();
      if (allCached.isNotEmpty) {
        final shuffled = List<Map<String, dynamic>>.from(allCached)..shuffle();
        if (mounted) {
          setState(() {
            _allDocs = shuffled;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Fetch from Firestore if cache is empty
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('prompts')
          .get();

      final List<Map<String, dynamic>> all = [];
      for (final doc in snapshot.docs) {
        final categoryId = doc.reference.parent.parent?.id ?? '';
        all.add({
          'docId': doc.id,
          'category': categoryId,
          ...doc.data(),
        });
      }

      // Save to memory cache
      FavoritesService.cachePrompts(all);

      final shuffled = List<Map<String, dynamic>>.from(all)..shuffle();

      if (mounted) {
        setState(() {
          _allDocs = shuffled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 64,
                  color: isDark ? Colors.grey[700] : Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load prompts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[600] : Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _loadAllPrompts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    // ── Random explore grid (when query is empty) ──
    if (widget.searchQuery.trim().isEmpty) {
      if (_allDocs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 64,
                color: isDark ? Colors.grey[750] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Prompts Found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: const Color(0xFFFF0000),
        onRefresh: _loadAllPrompts,
        child: PinterestGrid(
          docs: _allDocs,
          favorites: _favorites,
          onToggleFavorite: _toggleFavorite,
          onRefreshFavorites: _loadFavorites,
        ),
      );
    }

    // ── Search results state (when query is entered) ──
    final filteredDocs = _allDocs.where((doc) {
      final title = doc['title']?.toString().toLowerCase() ?? '';
      return title.contains(widget.searchQuery.trim().toLowerCase());
    }).toList();

    if (filteredDocs.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 80,
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No Results Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'No prompts match your search query "${widget.searchQuery}".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFF0000),
      onRefresh: _loadAllPrompts,
      child: PinterestGrid(
        docs: filteredDocs,
        favorites: _favorites,
        onToggleFavorite: _toggleFavorite,
        onRefreshFavorites: _loadFavorites,
      ),
    );
  }
}


