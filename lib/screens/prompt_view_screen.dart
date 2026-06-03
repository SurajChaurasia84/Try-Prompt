import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';

class PromptViewScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const PromptViewScreen({
    super.key,
    required this.data,
    required this.docId,
  });

  @override
  State<PromptViewScreen> createState() => _PromptViewScreenState();
}

class _PromptViewScreenState extends State<PromptViewScreen> with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isGenerating = false;
  bool _showPrompt = false;
  late AnimationController _typewriterController;
  String _currentTypedText = "";

  List<Map<String, dynamic>> _suggestedPrompts = [];
  Set<String> _favorites = {};
  bool _isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _loadFavorites();
    _fetchSuggestions();
    _typewriterController = AnimationController(
      vsync: this,
    );
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    final fav = await FavoritesService.isFavorite(widget.docId);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesService.getFavorites();
    if (mounted) {
      setState(() => _favorites = favs);
    }
    final synced = await FavoritesService.getFavorites(fetchFromFirestore: true);
    if (mounted) {
      setState(() => _favorites = synced);
    }
  }

  Future<void> _toggleSuggestionFavorite(String docId) async {
    await FavoritesService.toggleFavorite(docId);
    final favs = await FavoritesService.getFavorites();
    if (mounted) {
      setState(() => _favorites = favs);
    }
  }

  Future<void> _fetchSuggestions() async {
    if (!mounted) return;
    setState(() => _isLoadingSuggestions = true);

    try {
      final currentType = widget.data['type'] as String? ?? '';
      if (currentType.isEmpty) {
        if (mounted) {
          setState(() {
            _suggestedPrompts = [];
            _isLoadingSuggestions = false;
          });
        }
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('prompts')
          .where('type', isEqualTo: currentType)
          .get();

      final List<Map<String, dynamic>> suggestions = [];
      for (final doc in snapshot.docs) {
        if (doc.id == widget.docId) continue; // Exclude current prompt

        final categoryId = doc.reference.parent.parent?.id ?? '';
        suggestions.add({
          'docId': doc.id,
          'category': categoryId,
          ...doc.data(),
        });
      }

      // Sort newest first
      suggestions.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _suggestedPrompts = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch suggestions: $e");
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  List<Map<String, dynamic>> _getLeftColumnSuggestions() {
    final left = <Map<String, dynamic>>[];
    for (var i = 0; i < _suggestedPrompts.length; i++) {
      if (i.isEven) left.add(_suggestedPrompts[i]);
    }
    return left;
  }

  List<Map<String, dynamic>> _getRightColumnSuggestions() {
    final right = <Map<String, dynamic>>[];
    for (var i = 0; i < _suggestedPrompts.length; i++) {
      if (i.isOdd) right.add(_suggestedPrompts[i]);
    }
    return right;
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.toggleFavorite(widget.docId);
    final fav = await FavoritesService.isFavorite(widget.docId);
    if (mounted) {
      setState(() => _isFavorite = fav);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              fav ? 'Added to Favorites ❤️' : 'Removed from Favorites'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _generatePrompt() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _showPrompt = false;
      _currentTypedText = "";
    });

    _typewriterController.reset();

    // Simulate prompt generation processing/loading
    await Future.delayed(const Duration(milliseconds: 1500));

    final prompt = widget.data['prompt'] as String? ?? '';

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _showPrompt = true;
      });

      final durationMs = (prompt.length * 40).clamp(1000, 5000);
      _typewriterController.duration = Duration(milliseconds: durationMs);

      final Animation<double> typingAnimation = Tween<double>(
        begin: 0.0,
        end: prompt.length.toDouble(),
      ).animate(CurvedAnimation(
        parent: _typewriterController,
        curve: Curves.easeOut,
      ));

      void listener() {
        if (mounted) {
          setState(() {
            _currentTypedText = prompt.substring(0, typingAnimation.value.round());
          });
        }
      }

      typingAnimation.addListener(listener);

      _typewriterController.forward().then((_) {
        typingAnimation.removeListener(listener);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final title = (widget.data['title'] as String?)?.trim() ?? 'Untitled';
    final imageUrl = (widget.data['imageUrl'] as String?)?.trim() ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Favorite
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(_isFavorite),
                color: _isFavorite ? Colors.red : null,
              ),
            ),
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image ──
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF0000)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, st) => Container(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Generate & Prompt Container Switcher ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _isGenerating
                      ? Column(
                          key: const ValueKey('prompt_card_loading'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              height: 120,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _showPrompt
                          ? Column(
                              key: const ValueKey('prompt_card'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(text: _currentTypedText),
                                          if (_typewriterController.isAnimating)
                                            WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 2),
                                                child: _BlinkingCursor(isDark: isDark),
                                              ),
                                            ),
                                        ],
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: isDark ? Colors.grey[300] : const Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Copy Prompt Button
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final prompt = widget.data['prompt'] as String? ?? '';
                                    await Clipboard.setData(ClipboardData(text: prompt));
                                    await HistoryService.saveToHistory(prompt);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Prompt copied to clipboard!'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 20),
                                  label: const Text(
                                    'Copy Prompt',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('generate_button_container'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton(
                                  onPressed: _generatePrompt,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Generate Prompt',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                ),

                const SizedBox(height: 12),
                // Follow Me & How To Use Buttons Row (Shown at all times)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          const urlString = 'https://www.instagram.com';
                          try {
                            final Uri uri = Uri.parse(urlString);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } catch (e) {
                            debugPrint("Error launching follow link: $e");
                          }
                        },
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text(
                          'Follow Me',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final link = (widget.data['link'] as String?)?.trim() ?? '';
                          final urlString = link.isNotEmpty ? link : 'https://www.youtube.com';
                          try {
                            final Uri uri = Uri.parse(urlString);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } catch (e) {
                            debugPrint("Error launching how to use link: $e");
                          }
                        },
                        icon: const Icon(Icons.help_outline_rounded, size: 18),
                        label: const Text(
                          'How To Use',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'More Like This',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Suggestions Grid
                _isLoadingSuggestions
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
                          ),
                        ),
                      )
                    : _suggestedPrompts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No similar prompts found',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  children: _getLeftColumnSuggestions()
                                      .map((doc) => _SuggestionCard(
                                            doc: doc,
                                            isFavorite: _favorites.contains(doc['docId']),
                                            onToggleFavorite: _toggleSuggestionFavorite,
                                            onRefresh: _loadFavorites,
                                          ))
                                      .toList(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Right column
                              Expanded(
                                child: Column(
                                  children: _getRightColumnSuggestions()
                                      .map((doc) => _SuggestionCard(
                                            doc: doc,
                                            isFavorite: _favorites.contains(doc['docId']),
                                            onToggleFavorite: _toggleSuggestionFavorite,
                                            onRefresh: _loadFavorites,
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final bool isDark;
  const _BlinkingCursor({required this.isDark});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, child) {
        return Opacity(
          opacity: _cursorController.value > 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 2,
            height: 14,
            color: widget.isDark ? Colors.redAccent : Colors.red,
          ),
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final bool isFavorite;
  final Future<void> Function(String docId) onToggleFavorite;
  final VoidCallback onRefresh;

  const _SuggestionCard({
    required this.doc,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRefresh,
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
