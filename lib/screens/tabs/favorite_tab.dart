import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FavoriteTab extends StatefulWidget {
  const FavoriteTab({super.key});

  @override
  State<FavoriteTab> createState() => _FavoriteTabState();
}

class _FavoriteTabState extends State<FavoriteTab> {
  // Mock favorites database list
  final List<Map<String, String>> _favorites = [
    {
      'title': 'Socratic Tutor',
      'desc': 'Ask questions that stimulate critical thinking. Act as a Socratic teacher helping a student understand math concepts.',
      'category': 'Education',
    },
    {
      'title': 'SQL Query Optimizer',
      'desc': 'Analyze the following PostgreSQL query and suggest indexed paths, rewritten joins, and structural improvements for speed.',
      'category': 'Coding',
    },
    {
      'title': 'Resume Enhancer',
      'desc': 'Rewrite my bullet points to emphasize impact using action verbs and the STAR framework (Situation, Task, Action, Result).',
      'category': 'Professional',
    },
  ];

  void _removeFavorite(int index) {
    setState(() {
      _favorites.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Favorite Prompts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            'Keep your most frequently used prompts handy.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Conditional Empty State
          Expanded(
            child: _favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No favorites yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon on any prompt to save it here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final item = _favorites[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['category']!,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite),
                                  color: primaryColor,
                                  iconSize: 20,
                                  onPressed: () => _removeFavorite(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['title']!,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['desc']!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: item['desc']!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Prompt copied to clipboard!'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text('Copy'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
