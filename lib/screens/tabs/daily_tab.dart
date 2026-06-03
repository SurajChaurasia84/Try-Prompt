import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/favorites_service.dart';
import 'home_tab.dart';

class DailyTab extends StatefulWidget {
  final String searchQuery;
  const DailyTab({super.key, this.searchQuery = ''});

  @override
  State<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<DailyTab> {
  List<Map<String, dynamic>> _dailyDocs = [];
  Set<String> _favorites = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDailyPrompts();
    _loadFavorites();
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
    final favs = await FavoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _favorites = favs;
      });
    }
  }

  Future<void> _loadDailyPrompts() async {
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
        final daily = allCached.where((doc) {
          final type = doc['type']?.toString().toLowerCase() ?? '';
          return type == 'daily';
        }).toList();
        
        if (mounted) {
          setState(() {
            _dailyDocs = daily;
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

      final daily = all.where((doc) {
        final type = doc['type']?.toString().toLowerCase() ?? '';
        return type == 'daily';
      }).toList();

      if (mounted) {
        setState(() {
          _dailyDocs = daily;
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
                'Failed to load daily prompts',
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
                onPressed: _loadDailyPrompts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    final filteredDocs = widget.searchQuery.isEmpty
        ? _dailyDocs
        : _dailyDocs.where((doc) {
            final title = doc['title']?.toString().toLowerCase() ?? '';
            return title.contains(widget.searchQuery.toLowerCase());
          }).toList();

    if (filteredDocs.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFFF0000),
        onRefresh: _loadDailyPrompts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 200,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.searchQuery.isEmpty ? Icons.calendar_today_outlined : Icons.search_off_outlined,
                  size: 64,
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.searchQuery.isEmpty ? 'No Daily Templates Found' : 'No Results Found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    widget.searchQuery.isEmpty
                        ? 'Daily prompt templates will appear here as they are released.'
                        : 'No prompts match your search query "${widget.searchQuery}".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFF0000),
      onRefresh: _loadDailyPrompts,
      child: PinterestGrid(
        docs: filteredDocs,
        favorites: _favorites,
        onToggleFavorite: _toggleFavorite,
        onRefreshFavorites: _loadFavorites,
      ),
    );
  }
}
