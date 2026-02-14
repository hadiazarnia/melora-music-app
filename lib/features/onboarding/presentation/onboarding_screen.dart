import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/melora_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    const _OnboardingPage(
      icon: Iconsax.music,
      title: MeloraStrings.onboardingTitle1,
      description: MeloraStrings.onboardingDesc1,
      gradient: [MeloraColors.primary, MeloraColors.primaryLight],
    ),
    const _OnboardingPage(
      icon: Iconsax.wifi,
      title: MeloraStrings.onboardingTitle2,
      description: MeloraStrings.onboardingDesc2,
      gradient: [MeloraColors.secondary, MeloraColors.secondaryLight],
    ),
    const _OnboardingPage(
      icon: Iconsax.magic_star,
      title: MeloraStrings.onboardingTitle3,
      description: MeloraStrings.onboardingDesc3,
      gradient: [MeloraColors.accent, MeloraColors.accentLight],
    ),
  ];

  Future<void> _complete() async {
    // Request permissions
    await [
      Permission.storage,
      Permission.audio,
      Permission.notification,
    ].request();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: context.isDark
                  ? MeloraColors.darkBg
                  : MeloraColors.lightBg,
            ),
          ),

          // Page content
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _OnboardingPageWidget(page: page);
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(MeloraDimens.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == index
                                ? MeloraColors.primary
                                : (context.isDark
                                      ? MeloraColors.darkBorder
                                      : MeloraColors.lightBorder),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: MeloraDimens.xxl),

                    // Buttons
                    MeloraButton(
                      text: _currentPage == _pages.length - 1
                          ? MeloraStrings.getStarted
                          : MeloraStrings.next,
                      variant: MeloraButtonVariant.gradient,
                      onPressed: _nextPage,
                    ),
                    const SizedBox(height: MeloraDimens.md),
                    if (_currentPage < _pages.length - 1)
                      MeloraButton(
                        text: MeloraStrings.skip,
                        variant: MeloraButtonVariant.ghost,
                        onPressed: _complete,
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Icon container with glow
          Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: LinearGradient(
                    colors: page.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.gradient[0].withOpacity(0.35),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(page.icon, size: 60, color: Colors.white),
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                curve: Curves.elasticOut,
                duration: 800.ms,
              ),

          const SizedBox(height: 48),

          // Title
          Text(
                page.title,
                textAlign: TextAlign.center,
                style: context.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Description
          Text(
                page.description,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.textSecondary,
                  height: 1.6,
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
