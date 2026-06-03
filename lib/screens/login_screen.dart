import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();
        if (!userDoc.exists) {
          await userDocRef.set({
            'uid': user.uid,
            'email': user.email ?? '',
            'displayName': user.displayName ?? '',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
          });
        } else {
          await userDocRef.update({
            'displayName': user.displayName ?? '',
            'photoUrl': user.photoURL ?? '',
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
      }
      
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

                    const PromptFeatureShowcase(),

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
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.3 : 0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                                                  child: InkWell(
                                      onTap: _signInWithGoogle,
                                      borderRadius: BorderRadius.circular(18),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // White circular badge containing the Google G Logo
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Image.asset(
                                              'assets/g.png',
                                              width: 18,
                                              height: 18,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
      ),
    );
  }
}



// ==========================================
// Prompt Showcase & Feature Animation
// ==========================================
class PromptFeatureShowcase extends StatefulWidget {
  const PromptFeatureShowcase({super.key});

  @override
  State<PromptFeatureShowcase> createState() => _PromptFeatureShowcaseState();
}

class _PromptFeatureShowcaseState extends State<PromptFeatureShowcase>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Animation sub-ranges
  late Animation<double> _imageSize;
  late Animation<double> _promptBoxScale;
  late Animation<double> _promptBoxOpacity;
  late Animation<double> _copyButtonOpacity;
  late Animation<double> _cursorOpacity;
  late Animation<Offset> _cursorPosition;
  late Animation<double> _cursorScale;
  late Animation<double> _copiedIndicatorOpacity;
  late Animation<Offset> _copiedIndicatorOffset;
  late Animation<double> _fadeAll;

  final String _targetPrompt = "Create a cinematic photo of a cyberpunk cat coding on a holographic terminal in a dark neon room, 8k resolution";
  String _currentTypedText = "";
  bool _isCopiedTextVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Image size shrinks from 140 to 75
    _imageSize = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(140.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 140.0, end: 75.0).chain(CurveTween(curve: Curves.easeInOutBack)), weight: 12),
      TweenSequenceItem(tween: ConstantTween<double>(75.0), weight: 68),
    ]).animate(_controller);

    // Prompt box expands from 0 to 1
    _promptBoxScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 28),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 8),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 64),
    ]).animate(_controller);

    _promptBoxOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 28),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 4),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 68),
    ]).animate(_controller);

    // Copy button fades in after typing is halfway
    _copyButtonOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 58),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 6),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 36),
    ]).animate(_controller);

    // Cursor indicator shows up, hovers to Copy, and clicks
    _cursorOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 4),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 16),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 4),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 16),
    ]).animate(_controller);

    // Cursor starts from text area and moves to Copy button position locally
    _cursorPosition = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(180, 16), end: const Offset(20, 16)).chain(CurveTween(curve: Curves.easeInOut)), weight: 68),
      TweenSequenceItem(tween: ConstantTween<Offset>(const Offset(20, 16)), weight: 32),
    ]).animate(_controller);

    // Cursor click scale down
    _cursorScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 68),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.75).chain(CurveTween(curve: Curves.easeIn)), weight: 4),
      TweenSequenceItem(tween: Tween<double>(begin: 0.75, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 4),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 24),
    ]).animate(_controller);

    // Copied badge pops up
    _copiedIndicatorOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 72),
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 6),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 14),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 8),
    ]).animate(_controller);

    _copiedIndicatorOffset = TweenSequence<Offset>([
      TweenSequenceItem(tween: ConstantTween<Offset>(const Offset(0, 10)), weight: 72),
      TweenSequenceItem(tween: Tween<Offset>(begin: const Offset(0, 10), end: const Offset(0, -15)).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: ConstantTween<Offset>(const Offset(0, -15)), weight: 18),
    ]).animate(_controller);

    // Fade out everything at the very end
    _fadeAll = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 92),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 8),
    ]).animate(_controller);

    _controller.addListener(() {
      final val = _controller.value;
      // Typewriter typing progress between 0.32 and 0.58
      if (val >= 0.32 && val <= 0.58) {
        final typingProgress = (val - 0.32) / 0.26;
        final int length = (_targetPrompt.length * typingProgress).round();
        if (length <= _targetPrompt.length) {
          setState(() {
            _currentTypedText = _targetPrompt.substring(0, length);
          });
        }
      } else if (val > 0.58) {
        if (_currentTypedText != _targetPrompt) {
          setState(() {
            _currentTypedText = _targetPrompt;
          });
        }
      } else if (val < 0.32) {
        if (_currentTypedText.isNotEmpty) {
          setState(() {
            _currentTypedText = "";
          });
        }
      }

      // Trigger copied indicator logic
      if (val >= 0.72 && val <= 0.92) {
        if (!_isCopiedTextVisible) {
          setState(() {
            _isCopiedTextVisible = true;
          });
        }
      } else {
        if (_isCopiedTextVisible) {
          setState(() {
            _isCopiedTextVisible = false;
          });
        }
      }
    });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAll.value.clamp(0.0, 1.0),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. AI Generated Image Card
                Positioned(
                  top: 10,
                  child: Container(
                    width: _imageSize.value,
                    height: _imageSize.value,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                        width: 1.5,
                      ),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2E0F0F), const Color(0xFF0F0F0F)]
                            : [const Color(0xFFFFEBEB), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          // Abstract Grid Background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CyberGridPainter(
                                color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.25),
                              ),
                            ),
                          ),
                          // Glowing Center Gradient (mimicking AI content)
                          Center(
                            child: Container(
                              width: _imageSize.value * 0.8,
                              height: _imageSize.value * 0.8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    primaryColor.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Psychology/Mind Icon representing AI Prompts
                          Center(
                            child: Icon(
                              Icons.psychology_outlined,
                              size: _imageSize.value * 0.65,
                              color: primaryColor.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 10,
                  child: Opacity(
                    opacity: _promptBoxOpacity.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: _promptBoxScale.value,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Text Typing Area
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(text: _currentTypedText),
                                        // Blinking cursor
                                        if (_controller.value < 0.58)
                                          WidgetSpan(
                                            child: _BlinkingCursor(isDark: isDark),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Copy Button Area with Tooltip Overlay
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Copy Icon Button
                                    Opacity(
                                      opacity: _copyButtonOpacity.value.clamp(0.0, 1.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _isCopiedTextVisible
                                              ? Colors.green.withValues(alpha: 0.15)
                                              : primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _isCopiedTextVisible ? Icons.check_circle : Icons.copy_rounded,
                                          color: _isCopiedTextVisible ? Colors.green : primaryColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),

                                    // "Copied!" Floating Tooltip
                                    Positioned(
                                      top: _copiedIndicatorOffset.value.dy,
                                      left: -15,
                                      child: Opacity(
                                        opacity: _copiedIndicatorOpacity.value.clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'Copied!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Localized cursor
                          Positioned(
                            right: _cursorPosition.value.dx,
                            bottom: _cursorPosition.value.dy,
                            child: Opacity(
                              opacity: _cursorOpacity.value.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: _cursorScale.value,
                                child: const Icon(
                                  Icons.touch_app,
                                  color: Colors.redAccent,
                                  size: 26,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Blinking Cursor Widget
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

// Grid painter to draw an AI processing grid inside the showcase image
class CyberGridPainter extends CustomPainter {
  final Color color;
  CyberGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const int gridCount = 8;
    final stepX = size.width / gridCount;
    final stepY = size.height / gridCount;

    for (int i = 0; i <= gridCount; i++) {
      canvas.drawLine(Offset(i * stepX, 0), Offset(i * stepX, size.height), paint);
      canvas.drawLine(Offset(0, i * stepY), Offset(size.width, i * stepY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
