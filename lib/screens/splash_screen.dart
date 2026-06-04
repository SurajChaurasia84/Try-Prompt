import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mainscreen.dart';

class SplashScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const SplashScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {
          _progress = _progressAnimation.value;
        });
      });

    _animationController.forward().then((_) {
      _navigateToHome();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MainScreen(
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final percentage = (_progress * 100).round();

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Squirclish App Logo with premium gradient border
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.5),
                          Colors.orangeAccent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                        borderRadius: BorderRadius.circular(19.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19.5),
                        child: Image.asset(
                          'assets/icon.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.rocket_launch,
                              color: primaryColor,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // App Name
                  Text(
                    'Try Prompt',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F0F0F),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Free AI Image Generator Prompts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Percentage Text
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Custom Gradient Linear Progress Bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withValues(alpha: 0.7),
                                Colors.orangeAccent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Loading Text
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
