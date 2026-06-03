import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/favorites_service.dart';

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

class _PromptViewScreenState extends State<PromptViewScreen> {
  bool _isFavorite = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final fav = await FavoritesService.isFavorite(widget.docId);
    if (mounted) setState(() => _isFavorite = fav);
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

  Future<void> _copyPrompt() async {
    final prompt = widget.data['prompt'] as String? ?? '';
    await Clipboard.setData(ClipboardData(text: prompt));
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  void _sharePrompt() {
    final title = widget.data['title'] as String? ?? '';
    final prompt = widget.data['prompt'] as String? ?? '';
    final link = widget.data['link'] as String? ?? '';
    final text = [
      if (title.isNotEmpty) title,
      if (prompt.isNotEmpty) prompt,
      if (link.isNotEmpty) link,
    ].join('\n\n');
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final title = (widget.data['title'] as String?)?.trim() ?? 'Untitled';
    final prompt = (widget.data['prompt'] as String?)?.trim() ?? '';
    final imageUrl = (widget.data['imageUrl'] as String?)?.trim() ?? '';
    final link = (widget.data['link'] as String?)?.trim() ?? '';
    final type = (widget.data['type'] as String?)?.trim() ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsible App Bar with image ──
          SliverAppBar(
            expandedHeight: imageUrl.isNotEmpty ? 340 : 0,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Favorite
              IconButton(
                icon: Container(
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
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(_isFavorite),
                      color: _isFavorite ? Colors.red : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
              // Share
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined,
                      color: Colors.white, size: 18),
                ),
                onPressed: _sharePrompt,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: imageUrl.isNotEmpty
                ? FlexibleSpaceBar(
                    background: Image.network(
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
                  )
                : null,
          ),

          // ── Content ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Category chip
                if (type.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),

                // Prompt section
                if (prompt.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Prompt',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // Copy button
                      GestureDetector(
                        onTap: _copyPrompt,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _copied
                                ? Colors.green.withValues(alpha: 0.15)
                                : primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _copied
                                  ? Colors.green.withValues(alpha: 0.4)
                                  : primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _copied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                size: 13,
                                color: _copied ? Colors.green : primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _copied ? 'Copied!' : 'Copy',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _copied ? Colors.green : primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1C)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey[800]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark
                            ? Colors.grey[300]
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Link
                if (link.isNotEmpty) ...[
                  Text(
                    'Reference',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1C)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey[800]!
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Text(
                      link,
                      style: TextStyle(
                        fontSize: 13,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),

      // ── Bottom action bar ──
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              // Copy button
              Expanded(
                child: GestureDetector(
                  onTap: _copyPrompt,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _copied ? Colors.green : primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _copied ? 'Copied!' : 'Copy Prompt',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Share
              GestureDetector(
                onTap: _sharePrompt,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1C)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
