import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/audio_player_service.dart';
import 'core/services/favorites_service.dart';
import 'core/services/music_cache_service.dart';
import 'core/services/equalizer_service.dart';
import 'core/services/file_import_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'routes/app_router.dart';
import 'shared/providers/app_providers.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Hive.initFlutter();
  await Hive.openBox('melora_settings');

  final favoritesService = FavoritesService();
  await favoritesService.init();

  final musicCacheService = MusicCacheService();
  await musicCacheService.init();

  final equalizerService = EqualizerService();
  await equalizerService.init();

  final audioHandler = await AudioService.init(
    builder: () => MeloraAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.melora.music.channel',
      androidNotificationChannelName: 'Melora Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      notificationColor: Color(0xFF6C5CE7),
    ),
  );

  // Initialize file import (Open In / Share)
  await FileImportService.init();

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        favoritesServiceProvider.overrideWithValue(favoritesService),
        musicCacheServiceProvider.overrideWithValue(musicCacheService),
        equalizerServiceProvider.overrideWithValue(equalizerService),
      ],
      child: const MeloraApp(),
    ),
  );
}

class MeloraApp extends ConsumerStatefulWidget {
  const MeloraApp({super.key});

  @override
  ConsumerState<MeloraApp> createState() => _MeloraAppState();
}

class _MeloraAppState extends ConsumerState<MeloraApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFileImport();
  }

  void _setupFileImport() {
    FileImportService.setOnFileImported((filePath) async {
      try {
        final file = File(filePath);
        if (!await file.exists()) return;

        final song = await FileImportService.fileToSongModel(file);

        // Clear cache so new file shows in library
        final cacheService = ref.read(musicCacheServiceProvider);
        await cacheService.clearCache();

        // Play the imported song
        ref.read(audioHandlerProvider).playSong(song);

        // Refresh library
        ref.read(musicRefreshProvider.notifier).state++;

        // Show notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing: ${song.displayTitle}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Import error: $e');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when coming back to app (in case new files were added)
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);
    ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Melora',
      debugShowCheckedModeBanner: false,
      theme: MeloraTheme.lightTheme,
      darkTheme: MeloraTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
