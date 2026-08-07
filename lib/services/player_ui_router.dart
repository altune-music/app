import 'package:flutter/material.dart';

class PlayerUIRouter {
  static final PlayerUIRouter _instance = PlayerUIRouter._internal();
  factory PlayerUIRouter() => _instance;
  PlayerUIRouter._internal();

  late final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<bool> _hideMiniPlayer = ValueNotifier<bool>(false);

  void init(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  ValueNotifier<bool> get hideMiniPlayer => _hideMiniPlayer;

  void openFullPlayer(Widget fullPlayerScreen) {
    _hideMiniPlayer.value = true;
    navigatorKey.currentState?.push(_bottomToTopRoute(fullPlayerScreen)).then((
      _,
    ) {
      _hideMiniPlayer.value = false;
    });
  }

  Route _bottomToTopRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  void closeFullPlayer() {
    _hideMiniPlayer.value = false;
    navigatorKey.currentState?.pop();
  }

  bool canGoBack() {
    return navigatorKey.currentState?.canPop() ?? false;
  }
}
