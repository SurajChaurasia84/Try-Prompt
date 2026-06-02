import 'package:flutter/material.dart';

class FavoriteTab extends StatelessWidget {
  final bool isScreen;

  const FavoriteTab({
    super.key,
    this.isScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isScreen) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Favorite Prompts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
        body: const SizedBox(),
      );
    }
    return const SizedBox();
  }
}
