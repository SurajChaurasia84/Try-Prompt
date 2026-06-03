import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import '../../services/favorites_service.dart';

class CategoryPromptsScreen extends StatefulWidget {
  final String categoryName;
  final List<Map<String, dynamic>> docs;
  final Set<String> favorites;
  final Future<void> Function(String) onToggleFavorite;
  final VoidCallback onRefreshFavorites;

  const CategoryPromptsScreen({
    super.key,
    required this.categoryName,
    required this.docs,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onRefreshFavorites,
  });

  @override
  State<CategoryPromptsScreen> createState() => _CategoryPromptsScreenState();
}

class _CategoryPromptsScreenState extends State<CategoryPromptsScreen> {
  Set<String> _localFavorites = {};

  @override
  void initState() {
    super.initState();
    _localFavorites = Set.from(widget.favorites);
  }

  Future<void> _toggleFavorite(String docId) async {
    await widget.onToggleFavorite(docId);
    final favs = await FavoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _localFavorites = favs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: widget.docs.isEmpty
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
                docs: widget.docs,
                favorites: _localFavorites,
                onToggleFavorite: _toggleFavorite,
                onRefreshFavorites: widget.onRefreshFavorites,
              ),
      ),
    );
  }
}
