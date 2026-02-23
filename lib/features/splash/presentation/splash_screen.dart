import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initialize();
  }

  Future<void> _initialize() async {
    // Pre-load music library in background
    ref.read(allSongsProvider);

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacementNamed(onboardingDone ? '/main' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeloraColors.darkBg,
      body: Stack(
        children: [
          // Background gradient circles
          Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        MeloraColors.primary.withAlpha(38),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.5, 0.5)),

          Positioned(
                bottom: -80,
                right: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        MeloraColors.secondary.withAlpha(31),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 800.ms)
              .scale(begin: const Offset(0.5, 0.5)),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with pulse effect
                AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: MeloraColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: MeloraColors.primary.withAlpha(
                                  (77 + _pulseController.value * 51).round(),
                                ),
                                blurRadius: 30 + _pulseController.value * 15,
                                spreadRadius: _pulseController.value * 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Iconsax.musicnote,
                            size: 48,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 1000.ms,
                    ),

                const SizedBox(height: 24),

                // App name
                const Text(
                      'Melora',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                // Tagline
                const Text(
                      'Feel the Music',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: MeloraColors.darkTextSecondary,
                        letterSpacing: 4,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),

          // Bottom loading indicator
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MeloraColors.primary.withAlpha(153),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
