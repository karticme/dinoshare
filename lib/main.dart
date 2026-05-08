import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';
import 'package:macos_window_utils/macos_window_utils.dart';

import 'pages/home.dart';
import 'pages/onboarding.dart';
import 'state/state_index.dart';
import 'style/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS) {
    await WindowManipulator.initialize();
    await WindowManipulator.setWindowMinSize(const Size(360, 600));
    await WindowManipulator.setWindowMaxSize(const Size(460, double.infinity));
    WindowManipulator.hideZoomButton();
    await WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.closeButton,
      offset: const Offset(20.0, 21.0),
    );
    await WindowManipulator.overrideStandardWindowButtonPosition(
      buttonType: NSWindowButtonType.miniaturizeButton,
      offset: const Offset(42.0, 21.0),
    );
    WindowManipulator.hideTitle();
    WindowManipulator.makeTitlebarTransparent();
    WindowManipulator.enableFullSizeContentView();
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await loadAppSettings();

  runApp(const DinoshareApp());
}

class DinoshareApp extends StatefulWidget {
  const DinoshareApp({super.key});

  @override
  State<DinoshareApp> createState() => _DinoshareAppState();
}

class _DinoshareAppState extends State<DinoshareApp>
    with WidgetsBindingObserver {
  final AppThemeController _themeController = AppThemeController();

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeController.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    return _navigatorKey.currentState?.maybePop() ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        transferService.stopDiscovery();
        transferService.stopReceiver();
        break;
      case AppLifecycleState.resumed:
        if (appAlwaysReceive.value) {
          transferService.startReceiver(deviceName: appDeviceName.value);
        }
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeProvider(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          final themeData = _themeController.themeData;
          final isDark = themeData.colors.brightness == Brightness.dark;

          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: const Color(0x00000000),
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: themeData.colors.background,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
          );

          return FTheme(
            data: themeData,
            child: CupertinoApp(
              navigatorKey: _navigatorKey,
              localizationsDelegates: const [
                ...FLocalizations.localizationsDelegates,
              ],
              supportedLocales: FLocalizations.supportedLocales,
              home: appOnboardingDone ? const Home() : const Onboarding(),
            ),
          );
        },
      ),
    );
  }
}
