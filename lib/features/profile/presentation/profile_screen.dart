import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/melora_bottom_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                MeloraDimens.pagePadding,
                MeloraDimens.lg,
                MeloraDimens.pagePadding,
                MeloraDimens.xxl,
              ),
              child: Column(
                children: [
                  // Profile avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: MeloraColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: MeloraColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Iconsax.profile_circle_copy,
                      size: 42,
                      color: Colors.white,
                    ),
                  ).animate().scale(
                    begin: const Offset(0.5, 0.5),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  ),
                  const SizedBox(height: MeloraDimens.lg),
                  Text(
                    MeloraStrings.guestUser,
                    style: context.textTheme.headlineMedium,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to sign in',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: MeloraColors.primary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),

          // ─── Sign In Options ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.all(MeloraDimens.lg),
                child: Column(
                  children: [
                    _SignInButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: MeloraStrings.signInWithGoogle,
                      color: const Color(0xFFDB4437),
                      onTap: () {},
                    ),
                    const SizedBox(height: MeloraDimens.sm),
                    _SignInButton(
                      icon: Icons.apple_rounded,
                      label: MeloraStrings.signInWithApple,
                      color: context.textPrimary,
                      onTap: () {},
                    ),
                    const SizedBox(height: MeloraDimens.sm),
                    _SignInButton(
                      icon: Iconsax.sms,
                      label: MeloraStrings.signInWithEmail,
                      color: MeloraColors.primary,
                      onTap: () {},
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.xxl)),

          // ─── Theme Section ──────────────────────────────
          SliverToBoxAdapter(child: _SectionTitle(title: 'Appearance')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: MeloraDimens.sm),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Iconsax.moon,
                      title: 'Theme',
                      subtitle: _themeLabel(themeMode),
                      onTap: () => _showThemePicker(context, ref),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Iconsax.arrange_square,
                      title: 'Tab Bar Position',
                      subtitle: 'Bottom',
                      onTap: () {},
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.xl)),

          // ─── Audio Section ──────────────────────────────
          const SliverToBoxAdapter(child: _SectionTitle(title: 'Audio')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: MeloraDimens.sm),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Iconsax.music,
                      title: MeloraStrings.equalizer,
                      onTap: () {},
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Iconsax.timer_1,
                      title: MeloraStrings.sleepTimer,
                      onTap: () => _showSleepTimerSheet(context),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Iconsax.setting_4,
                      title: MeloraStrings.audioSettings,
                      subtitle: 'Fade, decoder, playback',
                      onTap: () => _showAudioSettings(context),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Iconsax.lock,
                      title: 'Melora in Lock Screen',
                      trailing: Switch(value: true, onChanged: (_) {}),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: MeloraDimens.xl)),

          // ─── General Section ────────────────────────────
          SliverToBoxAdapter(child: _SectionTitle(title: 'General')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: MeloraDimens.sm),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Iconsax.refresh,
                      title: MeloraStrings.checkForUpdates,
                      onTap: () {},
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Iconsax.message_question,
                      title: MeloraStrings.helpAndFaq,
                      onTap: () => _launchUrl('https://melora.app/faq'),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Iconsax.info_circle,
                      title: MeloraStrings.about,
                      subtitle: 'Version ${MeloraStrings.appVersion}',
                      onTap: () => _showAboutSheet(context),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Iconsax.close_circle,
                      title: MeloraStrings.closeApp,
                      iconColor: MeloraColors.error,
                      onTap: () => SystemNavigator.pop(),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
            ),
          ),

          // Bottom space
          const SliverToBoxAdapter(child: SizedBox(height: 200)),
        ],
      ),
    );
  }

  String _themeLabel(MeloraThemeMode mode) {
    switch (mode) {
      case MeloraThemeMode.dark:
        return 'Dark';
      case MeloraThemeMode.light:
        return 'Light';
      case MeloraThemeMode.system:
        return 'System';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    MeloraBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(MeloraDimens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Theme', style: context.textTheme.headlineSmall),
            const SizedBox(height: MeloraDimens.xl),
            _ThemeOption(
              icon: Iconsax.moon,
              title: 'Dark Mode',
              isSelected: ref.read(themeProvider) == MeloraThemeMode.dark,
              onTap: () {
                ref.read(themeProvider.notifier).setTheme(MeloraThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Iconsax.sun_1,
              title: 'Light Mode',
              isSelected: ref.read(themeProvider) == MeloraThemeMode.light,
              onTap: () {
                ref
                    .read(themeProvider.notifier)
                    .setTheme(MeloraThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Iconsax.mobile,
              title: 'System Default',
              isSelected: ref.read(themeProvider) == MeloraThemeMode.system,
              onTap: () {
                ref
                    .read(themeProvider.notifier)
                    .setTheme(MeloraThemeMode.system);
                Navigator.pop(context);
              },
            ),
            SizedBox(height: context.bottomPadding + MeloraDimens.lg),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context) {
    MeloraBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(MeloraDimens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sleep Timer', style: context.textTheme.headlineSmall),
            const SizedBox(height: MeloraDimens.xl),
            for (final mins in [15, 30, 45, 60, 90])
              ListTile(
                leading: const Icon(Iconsax.timer_1, size: 22),
                title: Text('$mins minutes'),
                onTap: () => Navigator.pop(context),
              ),
            ListTile(
              leading: const Icon(Iconsax.music_play, size: 22),
              title: const Text('End of current song'),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: context.bottomPadding + MeloraDimens.lg),
          ],
        ),
      ),
    );
  }

  void _showAudioSettings(BuildContext context) {
    MeloraBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(MeloraDimens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audio Settings', style: context.textTheme.headlineSmall),
            const SizedBox(height: MeloraDimens.xl),
            const _AudioSettingSwitch(
              title: 'Fade in/out on skip',
              subtitle: 'Smooth transition when changing songs',
              value: true,
            ),
            const _AudioSettingSwitch(
              title: 'Pause when muted',
              subtitle: 'Pause playback when volume is 0',
              value: false,
            ),
            const _AudioSettingSwitch(
              title: 'Resume when un-muted',
              subtitle: 'Resume playback when volume is restored',
              value: false,
            ),
            const SizedBox(height: MeloraDimens.md),
            ListTile(
              title: const Text('Decoder'),
              subtitle: const Text('System default'),
              trailing: Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: context.textTertiary,
              ),
              contentPadding: EdgeInsets.zero,
              onTap: () {},
            ),
            SizedBox(height: context.bottomPadding + MeloraDimens.lg),
          ],
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    MeloraBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(MeloraDimens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: MeloraColors.primaryGradient,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: MeloraDimens.lg),
            Text('Melora', style: context.textTheme.headlineMedium),
            Text(
              'Version ${MeloraStrings.appVersion}',
              style: context.textTheme.bodySmall,
            ),
            const SizedBox(height: MeloraDimens.xxl),
            Text(
              'A modern music player with beautiful UI, offline playback, and online streaming.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: MeloraDimens.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _launchUrl('https://melora.app'),
                  child: const Text('Website'),
                ),
                TextButton(
                  onPressed: () => _launchUrl('https://melora.app/privacy'),
                  child: const Text('Privacy'),
                ),
                TextButton(
                  onPressed: () => _launchUrl('https://melora.app/terms'),
                  child: const Text('Terms'),
                ),
              ],
            ),
            SizedBox(height: context.bottomPadding + MeloraDimens.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Helper Widgets ──────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MeloraDimens.pagePadding,
        0,
        MeloraDimens.pagePadding,
        MeloraDimens.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.textTertiary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor ?? context.textSecondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing:
          trailing ??
          Icon(Iconsax.arrow_right_3, size: 18, color: context.textTertiary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: MeloraDimens.lg),
      dense: true,
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MeloraDimens.lg),
      child: Divider(height: 1, color: context.borderColor.withOpacity(0.3)),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SignInButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
            border: Border.all(color: context.borderColor, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: MeloraDimens.sm),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isSelected ? MeloraColors.primary : context.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? MeloraColors.primary : context.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: MeloraColors.primary,
              size: 22,
            )
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _AudioSettingSwitch extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;

  const _AudioSettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  State<_AudioSettingSwitch> createState() => _AudioSettingSwitchState();
}

class _AudioSettingSwitchState extends State<_AudioSettingSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      subtitle: Text(widget.subtitle, style: context.textTheme.bodySmall),
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
