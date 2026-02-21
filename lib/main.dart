import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/audio_player_service.dart';
import 'core/services/favorites_service.dart';
import 'core/services/music_cache_service.dart';
import 'core/services/equalizer_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'routes/app_router.dart';
import 'shared/providers/app_providers.dart';

// Global navigator key for notification tap handling
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI setup
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

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('melora_settings');

  // Initialize services
  final favoritesService = FavoritesService();
  await favoritesService.init();

  final musicCacheService = MusicCacheService();
  await musicCacheService.init();

  final equalizerService = EqualizerService();
  await equalizerService.init();

  // Initialize audio handler with notification tap callback
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - could check for new music files here
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
