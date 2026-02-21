import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ فیکس شده - از context.isDark استفاده می‌کنیم
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = context.isDark;

    final currentSong = ref.watch(currentSongProvider);
    final hasSong = currentSong.valueOrNull != null;

    final bottomPadding = hasSong
        ? MeloraDimens.miniPlayerHeight + MeloraDimens.tabBarHeight + 30
        : MeloraDimens.tabBarHeight + 20;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                MeloraDimens.pagePadding,
                MeloraDimens.lg,
                MeloraDimens.pagePadding,
                MeloraDimens.xl,
              ),
              child: Text(
                'Settings',
                style: context.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Profile Section
          SliverToBoxAdapter(
            child: _SettingsSection(children: [_ProfileCard()]),
          ),

          // Playback Section
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Playback',
              children: [
                _SettingsTile(
                  icon: Iconsax.music,
                  iconColor: MeloraColors.primary,
                  title: 'Equalizer',
                  subtitle: 'Customize audio frequencies',
                  onTap: () => Navigator.pushNamed(context, '/equalizer'),
                ),
                _SettingsTile(
                  icon: Iconsax.timer_1,
                  iconColor: MeloraColors.accent,
                  title: 'Sleep Timer',
                  subtitle: 'Auto stop playback',
                  onTap: () => _showSleepTimerDialog(context, ref),
                ),
                _SettingsTile(
                  icon: Iconsax.speedometer,
                  iconColor: MeloraColors.secondary,
                  title: 'Playback Speed',
                  subtitle: 'Adjust playback speed',
                  onTap: () => _showSpeedDialog(context, ref),
                ),
                _SettingsTile(
                  icon: Iconsax.audio_square,
                  iconColor: MeloraColors.warning,
                  title: 'Audio Quality',
                  subtitle: 'High quality audio',
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: MeloraColors.primary,
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.volume_high,
                  iconColor: MeloraColors.success,
                  title: 'Gapless Playback',
                  subtitle: 'Seamless track transitions',
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: MeloraColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Appearance Section
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Appearance',
              children: [
                // ✅ فیکس شده
                _SettingsTile(
                  icon: isDark ? Iconsax.moon : Iconsax.sun_1,
                  iconColor: isDark
                      ? MeloraColors.accent
                      : MeloraColors.warning,
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Currently dark' : 'Currently light',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (val) {
                      themeNotifier.toggleTheme();
                      HapticFeedback.lightImpact();
                    },
                    activeColor: MeloraColors.primary,
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.colorfilter,
                  iconColor: MeloraColors.secondary,
                  title: 'Accent Color',
                  subtitle: 'Purple',
                  onTap: () => _showAccentColorDialog(context),
                ),
              ],
            ),
          ),

          // Library Section
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Library',
              children: [
                _SettingsTile(
                  icon: Iconsax.refresh,
                  iconColor: MeloraColors.accent,
                  title: 'Rescan Library',
                  subtitle: 'Scan for new music files',
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final refresh = ref.read(refreshMusicLibraryProvider);
                    await refresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Library refreshed'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                _SettingsTile(
                  icon: Iconsax.folder_add,
                  iconColor: MeloraColors.primary,
                  title: 'Excluded Folders',
                  subtitle: 'Manage excluded folders',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Iconsax.filter,
                  iconColor: MeloraColors.warning,
                  title: 'Filter Short Audio',
                  subtitle: 'Hide audio less than 30 seconds',
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: MeloraColors.primary,
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.trash,
                  iconColor: MeloraColors.error,
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  onTap: () => _showClearCacheDialog(context, ref),
                ),
              ],
            ),
          ),

          // Notification Section
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'Notifications',
              children: [
                _SettingsTile(
                  icon: Iconsax.notification,
                  iconColor: MeloraColors.secondary,
                  title: 'Show Notifications',
                  subtitle: 'Music playback controls',
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: MeloraColors.primary,
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.image,
                  iconColor: MeloraColors.accent,
                  title: 'Show Album Art',
                  subtitle: 'In notification panel',
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: MeloraColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // About Section
          SliverToBoxAdapter(
            child: _SettingsSection(
              title: 'About',
              children: [
                _SettingsTile(
                  icon: Iconsax.info_circle,
                  iconColor: MeloraColors.primary,
                  title: 'About Melora',
                  subtitle: 'Version ${MeloraStrings.appVersion}',
                  onTap: () => _showAboutDialog(context),
                ),
                _SettingsTile(
                  icon: Iconsax.document,
                  iconColor: MeloraColors.accent,
                  title: 'Privacy Policy',
                  onTap: () => _launchUrl('https://melora.app/privacy'),
                ),
                _SettingsTile(
                  icon: Iconsax.shield_tick,
                  iconColor: MeloraColors.success,
                  title: 'Terms of Service',
                  onTap: () => _launchUrl('https://melora.app/terms'),
                ),
                _SettingsTile(
                  icon: Iconsax.star,
                  iconColor: MeloraColors.warning,
                  title: 'Rate App',
                  subtitle: 'Support us with a review',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Iconsax.message_question,
                  iconColor: MeloraColors.secondary,
                  title: 'Help & Feedback',
                  onTap: () => _launchUrl('mailto:support@melora.app'),
                ),
              ],
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PROFILE CARD
// ═══════════════════════════════════════════════════════════

class _ProfileCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);
    final favCount = ref.watch(favoritesServiceProvider).favoriteCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: MeloraDimens.pagePadding),
      padding: const EdgeInsets.all(MeloraDimens.lg),
      decoration: BoxDecoration(
        gradient: MeloraColors.primaryGradient,
        borderRadius: BorderRadius.circular(MeloraDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: MeloraColors.primary.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Iconsax.music_library_2,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: MeloraDimens.lg),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Library',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                songsAsync.when(
                  data: (songs) => Text(
                    '${songs.length} songs • $favCount favorites',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                  loading: () => Text(
                    'Loading...',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Error loading library',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arrow
          Icon(
            Iconsax.arrow_right_3,
            color: Colors.white.withAlpha(179),
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SETTINGS SECTION
// ═══════════════════════════════════════════════════════════

class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MeloraDimens.pagePadding,
              MeloraDimens.xl,
              MeloraDimens.pagePadding,
              MeloraDimens.sm,
            ),
            child: Text(
              title!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ...children,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SETTINGS TILE
// ═══════════════════════════════════════════════════════════

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: MeloraDimens.pagePadding,
        vertical: MeloraDimens.xs,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: context.textTertiary,
              ),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: context.textTertiary,
                )
              : null),
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DIALOGS
// ═══════════════════════════════════════════════════════════

void _showSleepTimerDialog(BuildContext context, WidgetRef ref) {
  final sleepTimer = ref.read(sleepTimerProvider.notifier);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurface
            : MeloraColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(MeloraDimens.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.textTertiary.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          const Text(
            'Sleep Timer',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MeloraDimens.xl),
          Wrap(
            spacing: MeloraDimens.md,
            runSpacing: MeloraDimens.md,
            children: [
              _timerOption(
                ctx,
                '5 min',
                const Duration(minutes: 5),
                sleepTimer,
              ),
              _timerOption(
                ctx,
                '10 min',
                const Duration(minutes: 10),
                sleepTimer,
              ),
              _timerOption(
                ctx,
                '15 min',
                const Duration(minutes: 15),
                sleepTimer,
              ),
              _timerOption(
                ctx,
                '30 min',
                const Duration(minutes: 30),
                sleepTimer,
              ),
              _timerOption(
                ctx,
                '45 min',
                const Duration(minutes: 45),
                sleepTimer,
              ),
              _timerOption(ctx, '1 hour', const Duration(hours: 1), sleepTimer),
              _timerOption(
                ctx,
                '2 hours',
                const Duration(hours: 2),
                sleepTimer,
              ),
            ],
          ),
          SizedBox(height: context.bottomPadding + MeloraDimens.lg),
        ],
      ),
    ),
  );
}

Widget _timerOption(
  BuildContext ctx,
  String label,
  Duration duration,
  SleepTimerNotifier notifier,
) {
  return ActionChip(
    label: Text(label),
    onPressed: () {
      notifier.startTimer(duration);
      HapticFeedback.lightImpact();
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Sleep timer set for $label'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
  );
}

void _showSpeedDialog(BuildContext context, WidgetRef ref) {
  final handler = ref.read(audioHandlerProvider);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurface
            : MeloraColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(MeloraDimens.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.textTertiary.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          const Text(
            'Playback Speed',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MeloraDimens.xl),
          Wrap(
            spacing: MeloraDimens.md,
            runSpacing: MeloraDimens.md,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
              return ChoiceChip(
                label: Text('${speed}x'),
                selected: false,
                onSelected: (_) {
                  handler.setSpeed(speed);
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
          SizedBox(height: context.bottomPadding + MeloraDimens.lg),
        ],
      ),
    ),
  );
}

void _showAccentColorDialog(BuildContext context) {
  final colors = [
    (MeloraColors.primary, 'Purple'),
    (MeloraColors.secondary, 'Pink'),
    (MeloraColors.accent, 'Cyan'),
    (MeloraColors.success, 'Green'),
    (MeloraColors.warning, 'Orange'),
    (MeloraColors.error, 'Red'),
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurface
            : MeloraColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(MeloraDimens.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.textTertiary.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          const Text(
            'Accent Color',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MeloraDimens.xl),
          Wrap(
            spacing: MeloraDimens.lg,
            runSpacing: MeloraDimens.lg,
            children: colors.map((item) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                },
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.$1,
                        shape: BoxShape.circle,
                        border: item.$1 == MeloraColors.primary
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: item.$1.withAlpha(102),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: item.$1 == MeloraColors.primary
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: context.bottomPadding + MeloraDimens.lg),
        ],
      ),
    ),
  );
}

void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Clear Cache'),
      content: const Text(
        'This will clear cached music data and album artwork. Your music files will not be affected.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final cacheService = ref.read(musicCacheServiceProvider);
            await cacheService.clearCache();
            ref.read(musicRefreshProvider.notifier).state++;
            HapticFeedback.mediumImpact();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: const Text(
            'Clear',
            style: TextStyle(color: MeloraColors.error),
          ),
        ),
      ],
    ),
  );
}

void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: MeloraColors.primaryGradient,
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          const Text(
            'Melora',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version ${MeloraStrings.appVersion}',
            style: TextStyle(color: context.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: MeloraDimens.lg),
          Text(
            'A beautiful offline music player\nFeel the Music',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          Text(
            '© 2024 Melora. All rights reserved.',
            style: TextStyle(color: context.textTertiary, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
