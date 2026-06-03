import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/favorites_service.dart';
import '../prompt_view_screen.dart';

class FavoriteTab extends StatefulWidget {
  final bool isScreen;
  final bool isActive;
  final String searchQuery;

  const FavoriteTab({
    super.key,
    this.isScreen = false,
    this.isActive = false,
    this.searchQuery = '',
  });

  @override
  State<FavoriteTab> createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<FavoriteTab> {
  List<Map<String, dynamic>> _favoriteItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavorites();
  }

  @override
  void didUpdateWidget(FavoriteTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      // 1. Get from local cache first for instant loading
      final ids = await FavoritesService.getFavorites();
      
      // 2. Filter from the memory cache
      final cachedFavs = FavoritesService.getCachedFavorites(ids);
      
      // If cache matches the length of local IDs (or if no favorites saved at all)
      if (cachedFavs.length == ids.length || ids.isEmpty) {
        if (mounted) {
          setState(() {
            _favoriteItems = cachedFavs;
            _isLoading = false;
          });
        }
      } else {
        // If we have some items in the cache but not all, show cached ones immediately
        // so the user sees some UI, while we fetch the rest in the background.
        if (mounted) {
          setState(() {
            if (cachedFavs.isNotEmpty) {
              _favoriteItems = cachedFavs;
              _isLoading = false;
            } else if (_favoriteItems.isEmpty) {
              _isLoading = true;
            }
          });
        }
        
        // Fetch missing items from Firestore
        await _fetchItemsForIds(ids);
      }

      // 3. Sync with Firestore in the background and reload if the IDs changed
      final syncedIds = await FavoritesService.getFavorites(fetchFromFirestore: true);
      if (syncedIds.length != ids.length || !syncedIds.containsAll(ids)) {
        final syncedFavs = FavoritesService.getCachedFavorites(syncedIds);
        if (syncedFavs.length == syncedIds.length) {
          if (mounted) {
            setState(() {
              _favoriteItems = syncedFavs;
              _isLoading = false;
            });
          }
        } else {
          await _fetchItemsForIds(syncedIds);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchItemsForIds(Set<String> ids) async {
    if (ids.isEmpty) {
      if (mounted) {
        setState(() {
          _favoriteItems = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('prompts')
          .get();

      final items = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        if (ids.contains(doc.id)) {
          final categoryId = doc.reference.parent.parent?.id ?? '';
          items.add({
            'docId': doc.id,
            'category': categoryId,
            ...doc.data(),
          });
        }
      }

      // Save to memory cache so next tab visit is instant
      FavoritesService.cachePrompts(items);

      if (mounted) {
        setState(() {
          _favoriteItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String docId) async {
    await FavoritesService.toggleFavorite(docId);
    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from Favorites'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final body = _buildBody(isDark);

    if (widget.isScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Favorite Prompts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                'Your saved templates',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: body,
      );
    }
    return body;
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
        ),
      );
    }

    if (_favoriteItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Favorites Saved',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Tap the ❤️ on any prompt in the Home tab to save it here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredItems = widget.searchQuery.isEmpty
        ? _favoriteItems
        : _favoriteItems.where((item) {
            final title = item['title']?.toString().toLowerCase() ?? '';
            return title.contains(widget.searchQuery.toLowerCase());
          }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'No favorites match your search query "${widget.searchQuery}".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
              ),
            ),
          ],
        ),
      );
    }

    // Pinterest-style 2-column grid
    final left = <Map<String, dynamic>>[];
    final right = <Map<String, dynamic>>[];
    for (var i = 0; i < filteredItems.length; i++) {
      if (i.isEven) {
        left.add(_favoriteItems[i]);
      } else {
        right.add(_favoriteItems[i]);
      }
    }

    return RefreshIndicator(
      color: const Color(0xFFFF0000),
      onRefresh: _loadFavorites,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: left
                          .map((item) => _FavCard(
                                item: item,
                                onRemove: _removeFavorite,
                                onRefresh: _loadFavorites,
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: right
                          .map((item) => _FavCard(
                                item: item,
                                onRemove: _removeFavorite,
                                onRefresh: _loadFavorites,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Favorite card ────────────────────────────────────────────────────────────

class _FavCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Future<void> Function(String docId) onRemove;
  final VoidCallback onRefresh;

  const _FavCard({
    required this.item,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docId = item['docId'] as String;
    final imageUrl = (item['imageUrl'] as String?)?.trim() ?? '';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PromptViewScreen(
              data: Map<String, dynamic>.from(item)..remove('docId'),
              docId: docId,
            ),
          ),
        );
        onRefresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // ── Image ──
            if (imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 1.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey[100],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF0000)),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (ctx, err, st) => Container(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey[200],
                    height: 120,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey, size: 28),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                color:
                    isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: Colors.grey, size: 28),
                ),
              ),

            // ── Heart Overlay in Top Corner ──
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => onRemove(docId),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
