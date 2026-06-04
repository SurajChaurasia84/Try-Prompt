import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../services/favorites_service.dart';
import 'prompt_view_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CopiedPrompt> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToPromptView(CopiedPrompt entry) async {
    // Try to find the prompt in the cache
    final cached = FavoritesService.getCachedPrompts().firstWhere(
      (p) => p['prompt'] == entry.prompt,
      orElse: () => <String, dynamic>{},
    );

    final Map<String, dynamic> data;
    final String docId;

    if (cached.isNotEmpty) {
      docId = cached['docId'] as String;
      data = Map<String, dynamic>.from(cached)
        ..remove('docId')
        ..remove('category');
    } else {
      // Construct fallback data
      docId = 'history_${entry.prompt.hashCode}';
      final promptWords = entry.prompt.trim().split(RegExp(r'\s+'));
      final title = promptWords.take(4).join(' ') + (promptWords.length > 4 ? '...' : '');
      data = {
        'prompt': entry.prompt,
        'imageUrl': entry.imageUrl,
        'title': title,
        'type': '',
      };
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PromptViewScreen(data: data, docId: docId),
      ),
    );
    _loadHistory();
  }


  Future<void> _deleteItem(CopiedPrompt entry) async {
    await HistoryService.deleteFromHistory(entry);
    // Reload state locally without triggering full screen progress loading spinner
    final list = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = list;
      });
    }
  }

  Future<void> _clearAll() async {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear History',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to clear all copied prompts history?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await HistoryService.clearHistory();
                await _loadHistory();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'All History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black87),
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'clear') {
                _clearAll();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Clear History',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
                ),
              )
            : _history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: isDark ? Colors.grey[750] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No History Yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Your history will appear here.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                                ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final entry = _history[index];
                      return Dismissible(
                        key: ValueKey('${entry.prompt}_${entry.copiedAt.millisecondsSinceEpoch}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _deleteItem(entry);
                        },
                        child: GestureDetector(
                          onTap: () => _navigateToPromptView(entry),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left rounded image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: entry.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            entry.imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (ctx, child, progress) {
                                              if (progress == null) return child;
                                              return const Center(
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Color(0xFFFF0000),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (ctx, err, st) => Icon(
                                              Icons.assignment_outlined,
                                              color: primaryColor,
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.assignment_outlined,
                                          color: primaryColor,
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(width: 14),

                                // Right text content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        entry.prompt,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.grey[200] : Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatDateTime(entry.copiedAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                                          fontWeight: FontWeight.w500,
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
                    },
                  ),
      ),
    );
  }
}
