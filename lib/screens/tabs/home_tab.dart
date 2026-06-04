import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../prompt_view_screen.dart';
import '../../services/favorites_service.dart';
import '../category_prompts_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _activeFilter = 'Trending';
  Set<String> _favorites = {};

  // All loaded docs cached here; re-fetch via key
  final _refreshKey = GlobalKey<_PromptGridLoaderState>();

  @override
  void initState() {
    super.initState();
    FavoritesService.favoritesNotifier.addListener(_onFavoritesChanged);
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
    // 1. Get from local cache first for instant UI response
    final localFavs = await FavoritesService.getFavorites();
    if (mounted) {
      setState(() => _favorites = localFavs);
    }
    
    // 2. Fetch from Firestore in background and update the UI
    final syncedFavs = await FavoritesService.getFavorites(fetchFromFirestore: true);
    if (mounted) {
      setState(() => _favorites = syncedFavs);
    }
  }

  Future<void> _toggleFavorite(String docId) async {
    await FavoritesService.toggleFavorite(docId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _PromptGridLoader(
      key: _refreshKey,
      activeFilter: _activeFilter,
      favorites: _favorites,
      isDark: isDark,
      onFilterChange: (f) => setState(() => _activeFilter = f),
      onToggleFavorite: _toggleFavorite,
      onRefreshFavorites: _loadFavorites,
    );
  }
}

// ─── Fetches all prompts and renders them ─────────────────────────────────────

class _PromptGridLoader extends StatefulWidget {
  final String activeFilter;
  final Set<String> favorites;
  final bool isDark;
  final ValueChanged<String> onFilterChange;
  final Future<void> Function(String) onToggleFavorite;
  final VoidCallback onRefreshFavorites;

  const _PromptGridLoader({
    super.key,
    required this.activeFilter,
    required this.favorites,
    required this.isDark,
    required this.onFilterChange,
    required this.onToggleFavorite,
    required this.onRefreshFavorites,
  });

  @override
  State<_PromptGridLoader> createState() => _PromptGridLoaderState();
}

class _PromptGridLoaderState extends State<_PromptGridLoader> {
  List<Map<String, dynamic>> _allDocs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFromCacheAndFetch();
  }

  Future<void> _loadFromCacheAndFetch() async {
    // 1. Load from persistent cache first for instant startup
    final cached = await FavoritesService.loadPromptsFromLocalCache();
    if (cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allDocs = cached;
          _isLoading = false;
        });
      }
      FavoritesService.cachePrompts(cached);
    }

    // 2. Fetch from network in the background
    await _fetchAll(showSpinner: cached.isEmpty);
  }

  Future<void> _fetchAll({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
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

      // Sort newest first
      all.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        FavoritesService.cachePrompts(all);
        await FavoritesService.savePromptsToLocalCache(all); // Save to local cache
        setState(() {
          _allDocs = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _allDocs.isEmpty) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryColor = Theme.of(context).primaryColor;

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
                onPressed: _fetchAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    if (_allDocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined,
                size: 64,
                color: isDark ? Colors.grey[700] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Prompts Yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Explore new prompt designs and templates later as they get released.',
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

    // Build category chip list
    final Set<String> categorySet = {'Trending'};
    for (final doc in _allDocs) {
      final type = doc['type'] as String?;
      if (type != null && type.isNotEmpty) categorySet.add(type);
    }
    final cats = categorySet.toList();
    cats.remove('Trending');
    cats.sort();
    cats.insert(0, 'Trending');

    final filtered = _allDocs.where((doc) {
      final type = doc['type']?.toString().toLowerCase() ?? '';
      final category = doc['category']?.toString().toLowerCase() ?? '';
      return type != 'trending' && category != 'trending';
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFFFF0000),
      onRefresh: _fetchAll,
      child: Column(
        children: [
          // ── Category chips ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: cats.length,
                itemBuilder: (context, index) {
                  final cat = cats[index];
                  final isSelected = false; // Chips act as navigation triggers and remain unselected
                  return GestureDetector(
                    onTap: () {
                      final categoryDocs = _allDocs.where((d) {
                        final type = d['type']?.toString().toLowerCase() ?? '';
                        final category = d['category']?.toString().toLowerCase() ?? '';
                        final target = cat.toLowerCase();
                        return type == target || category == target;
                      }).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPromptsScreen(
                            categoryName: cat,
                            docs: categoryDocs,
                            favorites: widget.favorites,
                            onToggleFavorite: widget.onToggleFavorite,
                            onRefreshFavorites: widget.onRefreshFavorites,
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700]),
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Grid ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No prompts in this category',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : PinterestGrid(
                    docs: filtered,
                    favorites: widget.favorites,
                    onToggleFavorite: widget.onToggleFavorite,
                    onRefreshFavorites: widget.onRefreshFavorites,
                    header: () {
                      final trendingDocs = _allDocs.where((doc) {
                        final type = doc['type']?.toString().toLowerCase() ?? '';
                        final category = doc['category']?.toString().toLowerCase() ?? '';
                        return type == 'trending' || category == 'trending';
                      }).toList();

                      if (trendingDocs.isEmpty) return null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: trendingDocs.length,
                              itemBuilder: (context, index) {
                                final doc = trendingDocs[index];
                                final isFav = widget.favorites.contains(doc['docId']);
                                return TrendingCard(
                                  doc: doc,
                                  isFavorite: isFav,
                                  onToggleFavorite: widget.onToggleFavorite,
                                  onRefreshFavorites: widget.onRefreshFavorites,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Pinterest two-column grid ────────────────────────────────────────────────

class PinterestGrid extends StatefulWidget {
  final List<Map<String, dynamic>> docs;
  final Set<String> favorites;
  final Future<void> Function(String docId) onToggleFavorite;
  final VoidCallback onRefreshFavorites;
  final Widget? header;

  const PinterestGrid({
    super.key,
    required this.docs,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onRefreshFavorites,
    this.header,
  });

  @override
  State<PinterestGrid> createState() => _PinterestGridState();
}

class _PinterestGridState extends State<PinterestGrid> {
  late ScrollController _scrollController;
  int _displayLimit = 12;
  bool _isAddingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PinterestGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset limit when target documents list changes (e.g. changing active category)
    if (oldWidget.docs != widget.docs) {
      setState(() {
        _displayLimit = 12;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_displayLimit < widget.docs.length && !_isAddingMore) {
        setState(() {
          _isAddingMore = true;
        });

        // Small delay for smooth scroll visual loading feedback
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _displayLimit = (_displayLimit + 10).clamp(0, widget.docs.length);
              _isAddingMore = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedDocs = widget.docs.take(_displayLimit).toList();
    final left = <Map<String, dynamic>>[];
    final right = <Map<String, dynamic>>[];
    for (var i = 0; i < displayedDocs.length; i++) {
      if (i.isEven) {
        left.add(displayedDocs[i]);
      } else {
        right.add(displayedDocs[i]);
      }
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (widget.header != null)
          SliverToBoxAdapter(
            child: widget.header!,
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: left
                        .map((doc) => PromptCard(
                              doc: doc,
                              isFavorite: widget.favorites.contains(doc['docId']),
                              onToggleFavorite: widget.onToggleFavorite,
                              onRefreshFavorites: widget.onRefreshFavorites,
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: right
                        .map((doc) => PromptCard(
                              doc: doc,
                              isFavorite: widget.favorites.contains(doc['docId']),
                              onToggleFavorite: widget.onToggleFavorite,
                              onRefreshFavorites: widget.onRefreshFavorites,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_displayLimit < widget.docs.length)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 100),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 100),
            sliver: SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ),
      ],
    );
  }
}

// ─── Individual card ──────────────────────────────────────────────────────────

class PromptCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final bool isFavorite;
  final Future<void> Function(String docId) onToggleFavorite;
  final VoidCallback onRefreshFavorites;

  const PromptCard({
    required this.doc,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRefreshFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docId = doc['docId'] as String;
    final imageUrl = (doc['imageUrl'] as String?)?.trim() ?? '';

    // Build data map without the 'docId'/'category' helper fields
    final data = Map<String, dynamic>.from(doc)
      ..remove('docId')
      ..remove('category');

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PromptViewScreen(data: data, docId: docId),
          ),
        );
        onRefreshFavorites();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
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
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey[200],
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
                onTap: () => onToggleFavorite(docId),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      key: ValueKey(isFavorite),
                      size: 18,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
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

// ─── Trending Card ─────────────────────────────────────────────────────────────

class TrendingCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final bool isFavorite;
  final Future<void> Function(String) onToggleFavorite;
  final VoidCallback onRefreshFavorites;

  const TrendingCard({
    super.key,
    required this.doc,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRefreshFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docId = doc['docId'] as String;
    final imageUrl = (doc['imageUrl'] as String?)?.trim() ?? '';
    final title = (doc['title'] as String?)?.trim() ?? 'Untitled';

    final data = Map<String, dynamic>.from(doc)
      ..remove('docId')
      ..remove('category');

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PromptViewScreen(data: data, docId: docId),
          ),
        );
        onRefreshFavorites();
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, st) => Container(
                          color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200],
                          child: Icon(
                            Icons.image_outlined,
                            color: isDark ? Colors.grey[700] : Colors.grey[400],
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[200],
                        child: Icon(
                          Icons.image_outlined,
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                          size: 28,
                        ),
                      ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Content (Title & Favorite Heart button)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () async {
                        await onToggleFavorite(docId);
                      },
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
