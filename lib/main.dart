import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiosaavn/jiosaavn.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:dpad/dpad.dart';
import "models/song.dart";
import 'screens/library_home_screen.dart';
import 'controllers/main_controller.dart';
import 'services/player_manager.dart';
import 'services/state_service.dart';
import 'services/queue_manager.dart';
import 'services/player_ui_router.dart';
import 'services/log_service.dart';

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
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // just_audio_media_kit replaces the native player implementation; it conflicts
  // with just_audio_background on Android, so only use it on other platforms.
  if (!Platform.isAndroid) {
    JustAudioMediaKit.ensureInitialized();
  }
  LogService().debug('main: Starting JustAudioBackground.init', tag: 'main');
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'app.altune.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_notification_small',
    );
    LogService().debug('main: JustAudioBackground.init completed', tag: 'main');
  } catch (e) {
    // If JustAudioBackground.init fails, _audioHandler is never set and any
    // AudioPlayer construction crashes with LateInitializationError.
    // Rethrow so the developer sees the real root cause instead of a cryptic
    // crash later during playback.
    LogService().error(
      'main: JustAudioBackground.init failed',
      error: e,
      tag: 'main',
    );
    rethrow;
  }

  // Create PlayerManager (and thus AudioPlayer) AFTER JustAudioBackground.init
  // so just_audio_background's late _audioHandler is guaranteed to be set
  // before the platform player is activated.
  final queueManager = QueueManager();
  final playerManager = PlayerManager(queueManager: queueManager);

  runApp(MyApp(playerManager: playerManager, queueManager: queueManager));
}

class MyApp extends StatefulWidget {
  final PlayerManager playerManager;
  final QueueManager queueManager;

  const MyApp({
    super.key,
    required this.playerManager,
    required this.queueManager,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final navigatorKey = GlobalKey<NavigatorState>();
  late JioSaavnClient _client;
  late List<Song> _localSongs;
  late MainController _controller;
  bool _dpadUsed = false;

  PlayerManager get _playerManager => widget.playerManager;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    PlayerUIRouter().init(navigatorKey);
    _client = JioSaavnClient();
    _localSongs = [];
    _controller = MainController(
      client: _client,
      playerManager: _playerManager,
      localSongs: _localSongs,
      stateService: StateService(),
    );
    _controller.onLibraryChanged = () {
      if (mounted) setState(() {});
    };
    _controller.onCurrentPlayingChanged = () {
      if (mounted) setState(() {});
    };
    // Rebuild the theme when the user picks a new accent color in Settings.
    _controller.onThemeChanged = () {
      if (mounted) setState(() {});
    };
  }

  bool _onKey(KeyEvent event) {
    if (!_dpadUsed && event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          setState(() => _dpadUsed = true);
      }
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _playerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return Dpad(
          restoreFocus: false,
          theme: _dpadUsed ? null : const DpadThemeData(effects: []),
          onBack: () {
            // ponytail: don't pop routes here — Android fires a
            // separate platform popRoute that hits PopScope.
            // Handling both double-pops and closes the app.
            return false;
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      navigatorKey: navigatorKey,
      title: 'altune',
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _controller.themeColor.seedColor,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: LibraryHomeScreen(
        controller: _controller,
        playerManager: _playerManager,
        onPlaySaved: (song) async {
          await _controller.playSong(song);
        },
        onStreamSong: (song) async {
          await _controller.streamSong(song);
        },
        onAddToLibrary: (song) async {
          await _controller.toggleSongInLibrary(song);
        },
        onRemoveFromLibrary: (song) {
          _controller.removeFromLibrary(song);
        },
      ),
    );
  }
}
