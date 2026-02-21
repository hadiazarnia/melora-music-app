import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/providers/app_providers.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  bool _isEnabled = false;
  List<double> _bandLevels = List.filled(5, 0.0);
  String _currentPreset = 'flat';
  double _bassBoost = 0;
  double _virtualizer = 0;

  // Band frequencies
  static const List<String> _frequencies = [
    '60Hz',
    '230Hz',
    '910Hz',
    '3.6kHz',
    '14kHz',
  ];

  // Presets
  static const Map<String, List<double>> _presets = {
    'flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'bass_boost': [5.0, 3.5, 0.0, 0.0, 0.0],
    'treble_boost': [0.0, 0.0, 0.0, 3.5, 5.0],
    'vocal': [-2.0, 0.0, 3.0, 2.0, -1.0],
    'rock': [4.0, 2.5, -1.0, 2.5, 4.0],
    'pop': [-1.0, 2.0, 4.0, 2.0, -1.0],
    'jazz': [3.0, 1.0, -1.0, 1.5, 3.5],
    'classical': [4.0, 2.0, -1.0, 2.0, 4.0],
    'hip_hop': [4.5, 3.5, 0.0, 1.0, 3.0],
    'electronic': [4.0, 2.0, 0.0, 1.0, 4.0],
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final eqService = ref.read(equalizerServiceProvider);
      setState(() {
        _isEnabled = eqService.isEnabled;
        _bandLevels = eqService.bandLevels;
        _currentPreset = eqService.currentPreset;
      });
    } catch (e) {
      // Service not initialized, use defaults
    }
  }

  void _setPreset(String preset) {
    if (_presets.containsKey(preset)) {
      setState(() {
        _currentPreset = preset;
        _bandLevels = List.from(_presets[preset]!);
      });
      HapticFeedback.lightImpact();
    }
  }

  void _setBandLevel(int index, double value) {
    setState(() {
      _bandLevels[index] = value.clamp(-12.0, 12.0);
      _currentPreset = 'custom';
    });
  }

  void _resetEqualizer() {
    setState(() {
      _currentPreset = 'flat';
      _bandLevels = List.from(_presets['flat']!);
      _bassBoost = 0;
      _virtualizer = 0;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        actions: [
          IconButton(
            onPressed: _resetEqualizer,
            icon: const Icon(Iconsax.refresh),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MeloraDimens.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable Card
            _buildEnableCard(),

            const SizedBox(height: MeloraDimens.xxl),

            // Presets
            _buildSectionTitle('PRESETS'),
            const SizedBox(height: MeloraDimens.md),
            _buildPresetsGrid(),

            const SizedBox(height: MeloraDimens.xxl),

            // Equalizer Bands
            _buildSectionTitle('FREQUENCY BANDS'),
            const SizedBox(height: MeloraDimens.lg),
            _buildEqualizerBands(),

            const SizedBox(height: MeloraDimens.xxl),

            // Effects
            _buildSectionTitle('EFFECTS'),
            const SizedBox(height: MeloraDimens.md),
            _buildEffectsSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.textTertiary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildEnableCard() {
    return Container(
      padding: const EdgeInsets.all(MeloraDimens.lg),
      decoration: BoxDecoration(
        gradient: _isEnabled ? MeloraColors.primaryGradient : null,
        color: _isEnabled
            ? null
            : (context.isDark
                  ? MeloraColors.darkSurfaceLight
                  : MeloraColors.lightSurfaceLight),
        borderRadius: BorderRadius.circular(MeloraDimens.radiusXl),
        border: _isEnabled
            ? null
            : Border.all(color: context.borderColor.withAlpha(128), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _isEnabled
                  ? Colors.white.withAlpha(51)
                  : MeloraColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Iconsax.music,
              color: _isEnabled ? Colors.white : MeloraColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: MeloraDimens.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equalizer',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isEnabled ? Colors.white : context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isEnabled ? 'Active' : 'Disabled',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    color: _isEnabled
                        ? Colors.white.withAlpha(179)
                        : context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            onChanged: (val) {
              setState(() => _isEnabled = val);
              HapticFeedback.lightImpact();
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withAlpha(77),
            inactiveThumbColor: MeloraColors.primary,
            inactiveTrackColor: MeloraColors.primary.withAlpha(77),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsGrid() {
    final presetList = [
      ('flat', 'Flat', Iconsax.minus),
      ('bass_boost', 'Bass', Iconsax.volume_high),
      ('treble_boost', 'Treble', Iconsax.audio_square),
      ('vocal', 'Vocal', Iconsax.microphone),
      ('rock', 'Rock', Iconsax.music),
      ('pop', 'Pop', Iconsax.music_play),
      ('jazz', 'Jazz', Iconsax.music_square),
      ('classical', 'Classical', Iconsax.note_square),
      ('hip_hop', 'Hip Hop', Iconsax.headphone),
      ('electronic', 'EDM', Iconsax.cpu),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.8,
        crossAxisSpacing: MeloraDimens.xs,
        mainAxisSpacing: MeloraDimens.xs,
      ),
      itemCount: presetList.length,
      itemBuilder: (ctx, i) {
        final preset = presetList[i];
        final isSelected = _currentPreset == preset.$1;

        return GestureDetector(
          onTap: () => _setPreset(preset.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? MeloraColors.primary.withAlpha(26)
                  : (context.isDark
                        ? MeloraColors.darkSurfaceLight
                        : MeloraColors.lightSurfaceLight),
              borderRadius: BorderRadius.circular(MeloraDimens.radiusSm),
              border: Border.all(
                color: isSelected
                    ? MeloraColors.primary
                    : context.borderColor.withAlpha(51),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  preset.$3,
                  size: 18,
                  color: isSelected
                      ? MeloraColors.primary
                      : context.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  preset.$2,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? MeloraColors.primary
                        : context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEqualizerBands() {
    return Container(
      padding: const EdgeInsets.all(MeloraDimens.lg),
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurfaceLight
            : MeloraColors.lightSurfaceLight,
        borderRadius: BorderRadius.circular(MeloraDimens.radiusXl),
        border: Border.all(color: context.borderColor.withAlpha(77), width: 1),
      ),
      child: Column(
        children: [
          // dB Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '+12 dB',
                style: TextStyle(fontSize: 10, color: context.textTertiary),
              ),
              Text(
                '0 dB',
                style: TextStyle(fontSize: 10, color: context.textTertiary),
              ),
              Text(
                '-12 dB',
                style: TextStyle(fontSize: 10, color: context.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: MeloraDimens.sm),

          // Sliders
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return Column(
                  children: [
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _isEnabled
                                ? MeloraColors.primary
                                : context.textTertiary,
                            inactiveTrackColor: context.borderColor,
                            thumbColor: _isEnabled
                                ? MeloraColors.primary
                                : context.textTertiary,
                            overlayColor: MeloraColors.primary.withAlpha(38),
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                          ),
                          child: Slider(
                            value: _bandLevels[index],
                            min: -12,
                            max: 12,
                            onChanged: _isEnabled
                                ? (val) {
                                    _setBandLevel(index, val);
                                    HapticFeedback.selectionClick();
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: MeloraDimens.sm),
                    Text(
                      _frequencies[index],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectsSection() {
    return Column(
      children: [
        // Bass Boost
        _buildEffectSlider(
          icon: Iconsax.volume_high,
          title: 'Bass Boost',
          value: _bassBoost,
          onChanged: (val) => setState(() => _bassBoost = val),
        ),
        const SizedBox(height: MeloraDimens.lg),

        // Virtualizer
        _buildEffectSlider(
          icon: Iconsax.sound,
          title: 'Virtualizer',
          value: _virtualizer,
          onChanged: (val) => setState(() => _virtualizer = val),
        ),
      ],
    );
  }

  Widget _buildEffectSlider({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(MeloraDimens.lg),
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurfaceLight
            : MeloraColors.lightSurfaceLight,
        borderRadius: BorderRadius.circular(MeloraDimens.radiusLg),
        border: Border.all(color: context.borderColor.withAlpha(77), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: MeloraColors.primary),
              const SizedBox(width: MeloraDimens.sm),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: MeloraColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: MeloraDimens.md),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MeloraColors.primary,
              inactiveTrackColor: context.borderColor,
              thumbColor: MeloraColors.primary,
              overlayColor: MeloraColors.primary.withAlpha(38),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              onChanged: (val) {
                onChanged(val);
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }
}
