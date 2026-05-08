import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

enum AppThemeMode { light, dark, system }

class AppThemeController extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  set mode(AppThemeMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  FThemeData get themeData {
    if (_mode == AppThemeMode.light) {
      return dinoTouchTheme;
    }
    if (_mode == AppThemeMode.dark) {
      return dinoDarkTheme;
    }
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark ? dinoDarkTheme : dinoTouchTheme;
  }
}

class AppThemeProvider extends InheritedNotifier<AppThemeController> {
  const AppThemeProvider({
    super.key,
    required AppThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppThemeController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppThemeProvider>();
    assert(provider != null, 'AppThemeProvider not found in widget tree.');
    return provider!.notifier!;
  }
}

class DinoColors {
  // Light mode
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF0A0A0A);
  static const card = Color(0xFFFFFFFF);
  static const cardForeground = Color(0xFF0A0A0A);
  static const primary = Color(0xFF1447E6);
  static const primaryForeground = Color(0xFFEFF6FF);
  static const secondary = Color(0xFFF5F5F5);
  static const secondaryForeground = Color(0xFF171717);
  static const muted = Color(0xFFF5F5F5);
  static const mutedForeground = Color(0xFF737373);
  static const destructive = Color(0xFFFb2c36);
  static const destructiveForeground = Color(0xFFFEF2F2);
  static const border = Color(0xFFE5E5E5);
  static const input = Color(0xFFE5E5E5);
  static const ring = Color(0xFFA1A1A1);
  static const info = Color(0xFF3B82F6);
  static const infoForeground = Color(0xFFEFF6FF);
  static const success = Color(0xFF10B981);
  static const successForeground = Color(0xFFFFFFFF);
  static const warning = Color(0xFFF9A825);
  static const warningForeground = Color(0xFFFFFFFF);

  // Dark mode
  static const backgroundDark = Color(0xFF0A0A0A);
  static const foregroundDark = Color(0xFFF9FAFB);
  static const cardDark = Color(0xFF171717);
  static const cardForegroundDark = Color(0xFFF9FAFB);
  static const primaryDark = Color(0xFF193CB8);
  static const primaryForegroundDark = Color(0xFFEFF6FF);
  static const secondaryDark = Color(0xFF262626);
  static const secondaryForegroundDark = Color(0xFFF9FAFB);
  static const mutedDark = Color(0xFF262626);
  static const mutedForegroundDark = Color(0xFFA1A1A1);
  static const destructiveDark = Color(0xFFE6000B);
  static const destructiveForegroundDark = Color(0xFFFFEAEA);
  static const borderDark = Color(0x1AFFFFFF);
  static const inputDark = Color(0x26FFFFFF);
  static const ringDark = Color(0xFF737373);
  static const infoDark = Color(0xFF1563C7);
  static const infoForegroundDark = Color(0xFFEFF6FF);
  static const successDark = Color(0xFF047857);
  static const successForegroundDark = Color(0xFFECFDF5);
  static const warningDark = Color(0xFFF59E42);
  static const warningForegroundDark = Color(0xFFFFF8E1);
}

FColors dinoFColors({required bool dark}) => FColors(
  brightness: dark ? Brightness.dark : Brightness.light,
  systemOverlayStyle:
      dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
  barrier: dark ? Color(0x7A000000) : Color(0x33000000),
  background: dark ? DinoColors.backgroundDark : DinoColors.background,
  foreground: dark ? DinoColors.foregroundDark : DinoColors.foreground,
  primary: dark ? DinoColors.primaryDark : DinoColors.primary,
  primaryForeground:
      dark ? DinoColors.primaryForegroundDark : DinoColors.primaryForeground,
  secondary: dark ? DinoColors.secondaryDark : DinoColors.secondary,
  secondaryForeground:
      dark
          ? DinoColors.secondaryForegroundDark
          : DinoColors.secondaryForeground,
  muted: dark ? DinoColors.mutedDark : DinoColors.muted,
  mutedForeground:
      dark ? DinoColors.mutedForegroundDark : DinoColors.mutedForeground,
  destructive: dark ? DinoColors.destructiveDark : DinoColors.destructive,
  destructiveForeground:
      dark
          ? DinoColors.destructiveForegroundDark
          : DinoColors.destructiveForeground,
  error: dark ? DinoColors.destructiveDark : DinoColors.destructive,
  errorForeground:
      dark
          ? DinoColors.destructiveForegroundDark
          : DinoColors.destructiveForeground,
  card: dark ? DinoColors.cardDark : DinoColors.card,
  border: dark ? DinoColors.borderDark : DinoColors.border,
);

class DinoCustomColors {
  final Color input;
  final Color ring;
  final Color info;
  final Color infoForeground;
  final Color success;
  final Color successForeground;
  final Color warning;
  final Color warningForeground;

  const DinoCustomColors({
    required this.input,
    required this.ring,
    required this.info,
    required this.infoForeground,
    required this.success,
    required this.successForeground,
    required this.warning,
    required this.warningForeground,
  });
}

DinoCustomColors dinoCustomColors({required bool dark}) => DinoCustomColors(
  input: dark ? DinoColors.inputDark : DinoColors.input,
  ring: dark ? DinoColors.ringDark : DinoColors.ring,
  info: dark ? DinoColors.infoDark : DinoColors.info,
  infoForeground:
      dark ? DinoColors.infoForegroundDark : DinoColors.infoForeground,
  success: dark ? DinoColors.successDark : DinoColors.success,
  successForeground:
      dark ? DinoColors.successForegroundDark : DinoColors.successForeground,
  warning: dark ? DinoColors.warningDark : DinoColors.warning,
  warningForeground:
      dark ? DinoColors.warningForegroundDark : DinoColors.warningForeground,
);

FThemeData dinoTheme({required bool dark}) =>
    FThemeData(colors: dinoFColors(dark: dark), touch: true);

FThemeData get dinoTouchTheme => dinoTheme(dark: false);
FThemeData get dinoDarkTheme => dinoTheme(dark: true);
