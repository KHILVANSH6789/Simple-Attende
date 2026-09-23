// ============================================================
// lib/screens/intro/intro_screen.dart
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../providers/settings_provider.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  final AudioPlayer _player = AudioPlayer();
  bool _animationDone = false;

  @override
  void initState() {
    super.initState();

    // Slide + scale animation controller
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade-out screen controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: const Interval(0.5, 1.0)),
    );

    _logoFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _slideController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _fadeAnim = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startIntro();
  }

  Future<void> _startIntro() async {
    // Small delay before starting
    await Future.delayed(const Duration(milliseconds: 300));

    // Play intro sound
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    if (settingsProvider.soundEnabled) {
      await _player.play(AssetSource('audio/Intro_Sound.mp3'));
    }

    // Start slide-in animation
    await _slideController.forward();

    // Hold for a moment at center
    await Future.delayed(const Duration(milliseconds: 900));

    // Fade out to home
    setState(() => _animationDone = true);
    await _fadeController.forward();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _skipIntro() {
    if (!_animationDone) {
      _slideController.stop();
      _fadeController.forward().then((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = settings.colors;

    return GestureDetector(
      onTap: _skipIntro,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Scaffold(
          backgroundColor: colors.introBackground,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.introBackground,
                  colors.backgroundGradientEnd,
                  colors.introBackground,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Decorative background circles
                _buildBgDecor(colors),

                // Main content
                Center(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: FadeTransition(
                        opacity: _logoFadeAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glow + Logo
                            AnimatedBuilder(
                              animation: _glowAnim,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.accent.withOpacity(
                                            0.4 * _glowAnim.value),
                                        blurRadius: 60 * _glowAnim.value,
                                        spreadRadius: 10 * _glowAnim.value,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: Image.asset(
                                  'assets/images/SimpleAttende_AppIcon.png',
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            // App name
                            Text(
                              'Simple Attende',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Attendance, simplified.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.textMuted,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Tap to skip hint
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Tap to skip',
                      style: TextStyle(
                        color: colors.textMuted.withOpacity(0.6),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBgDecor(dynamic colors) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accentSecondary.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withOpacity(0.04),
            ),
          ),
        ),
      ],
    );
  }
}
