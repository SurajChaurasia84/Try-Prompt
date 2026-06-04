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
    _loadFavorites();
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
    final favs = await FavoritesService.getFavorites();
    if (mounted) setState(() => _favorites = favs);
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
    _fetchAll();
  }

  /// Step 1: get all category doc IDs from the root 'prompts' collection
  /// Step 2: for each category, fetch its 'prompts' subcollection
  /// This avoids needing a collectionGroup index.
  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
        setState(() {
          _allDocs = all;
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

    final filtered = _allDocs;

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
                      final categoryDocs = cat == 'Trending'
                          ? _allDocs
                          : _allDocs.where((d) => d['type'] == cat).toList();
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
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Pinterest two-column grid ────────────────────────────────────────────────

class PinterestGrid extends StatelessWidget {
  final List<Map<String, dynamic>> docs;
  final Set<String> favorites;
  final Future<void> Function(String docId) onToggleFavorite;
  final VoidCallback onRefreshFavorites;

  const PinterestGrid({
    required this.docs,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onRefreshFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final left = <Map<String, dynamic>>[];
    final right = <Map<String, dynamic>>[];
    for (var i = 0; i < docs.length; i++) {
      if (i.isEven) {
        left.add(docs[i]);
      } else {
        right.add(docs[i]);
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: left
                        .map((doc) => PromptCard(
                              doc: doc,
                              isFavorite: favorites.contains(doc['docId']),
                              onToggleFavorite: onToggleFavorite,
                              onRefreshFavorites: onRefreshFavorites,
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
                              isFavorite: favorites.contains(doc['docId']),
                              onToggleFavorite: onToggleFavorite,
                              onRefreshFavorites: onRefreshFavorites,
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
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
