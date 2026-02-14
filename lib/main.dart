import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/audio_player_service.dart';
import 'core/services/favorites_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'routes/app_router.dart';
import 'shared/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI
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

  // Initialize Favorites
  final favoritesService = FavoritesService();
  await favoritesService.init();

  // ✅ Initialize Audio Service with error handling
  late MeloraAudioHandler audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => MeloraAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.melora.music.channel',
        androidNotificationChannelName: 'Melora Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
  } catch (e) {
    debugPrint('AudioService init error: $e');
    // ✅ Fallback: ساخت handler بدون AudioService
    audioHandler = MeloraAudioHandler();
  }

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        favoritesServiceProvider.overrideWithValue(favoritesService),
      ],
      child: const MeloraApp(),
    ),
  );
}

class MeloraApp extends ConsumerWidget {
  const MeloraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeProvider.notifier);
    ref.watch(themeProvider);

    return MaterialApp(
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
