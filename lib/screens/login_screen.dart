import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${googleUser.displayName}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Sleek Background (Dark Mode / Reddish hues)
          Container(
            color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F9F9),
          ),

          // 2. Glowing Spheres in Background (Abstract modern graphics)
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF0000).withValues(alpha: isDark ? 0.15 : 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          Positioned(
            bottom: -size.height * 0.2,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D4D).withValues(alpha: isDark ? 0.12 : 0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 3. Main content structured with Top and Bottom groups
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Section: Logo, Title, Subtitle
                    Column(
                      children: [
                        const SizedBox(height: 48),
                        // App Logo Container
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF0000).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              'assets/icon.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFFF0000),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Title
                        const Text(
                          'Try Prompt',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          'Unlock your creative AI power',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    // Bottom Section: Google Sign-In button and Terms
                    Column(
                      children: [
                        // Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _signInWithGoogle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                                    foregroundColor: isDark ? Colors.white : Colors.black87,
                                    elevation: 2,
                                    shadowColor: Colors.black.withValues(alpha: 0.15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(
                                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Custom Painted Google Logo
                                      CustomPaint(
                                        size: const Size(20, 20),
                                        painter: GoogleGLogoPainter(),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Draw Google "G" logo precisely using standard Flutter Canvas
class GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Google red color arc
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..relativeLineTo(-w * 0.35, -h * 0.35)
      ..arcTo(
        Rect.fromLTWH(0, 0, w, h),
        -2.356, // starting angle in rad
        1.57,  // sweep angle in rad
        false,
      )
      ..lineTo(w * 0.5, h * 0.5);
    canvas.drawPath(redPath, paint);

    // Google yellow color arc
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..relativeLineTo(-w * 0.35, h * 0.35)
      ..arcTo(
        Rect.fromLTWH(0, 0, w, h),
        2.356,
        -1.57,
        false,
      )
      ..lineTo(w * 0.5, h * 0.5);
    canvas.drawPath(yellowPath, paint);

    // Google green color arc
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..relativeLineTo(w * 0.35, h * 0.35)
      ..arcTo(
        Rect.fromLTWH(0, 0, w, h),
        0.785,
        1.571,
        false,
      )
      ..lineTo(w * 0.5, h * 0.5);
    canvas.drawPath(greenPath, paint);

    // Google blue color arc & center cross-bar
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..relativeLineTo(w * 0.35, -h * 0.35)
      ..arcTo(
        Rect.fromLTWH(0, 0, w, h),
        -0.785,
        1.57,
        false,
      )
      ..lineTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.95, h * 0.5)
      ..lineTo(w * 0.95, h * 0.6)
      ..lineTo(w * 0.5, h * 0.6)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Inner transparent circle to make it a ring/arc
    paint.color = Colors.white; // Or background color, but white is ideal inside logo card
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.28, paint);

    // Clean G cutouts (clear empty center bar area above cross bar)
    final Path clearPath = Path()
      ..moveTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.95, h * 0.5)
      ..lineTo(w * 0.95, h * 0.15)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    // draw clearPath with white to cut out the top right
    canvas.drawPath(clearPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
