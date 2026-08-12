import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Holds the user's light/dark/system preference and persists it.
///
/// Deliberately backed by `shared_preferences` rather than the secure storage
/// used for the auth token: a theme choice is not a secret, and secure storage
/// on Android is slow enough that reading it during startup would be visible.
class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'theme_mode';

  final SharedPreferences? _prefs;

  ThemeMode _themeMode;

  ThemeProvider({SharedPreferences? prefs, ThemeMode initial = ThemeMode.system})
      : _prefs = prefs,
        _themeMode = initial;

  /// Loads the persisted preference before the first frame.
  ///
  /// Done eagerly in `main` rather than lazily in the widget tree so the app
  /// never paints one theme and then swaps to the other a frame later.
  static Future<ThemeProvider> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return ThemeProvider(
        prefs: prefs,
        initial: _decode(prefs.getString(_storageKey)),
      );
    } catch (e, s) {
      // A failure here is not worth blocking startup for — fall back to
      // following the system and simply do not persist.
      AppLogger.error('Could not read the saved theme preference', e, s);
      return ThemeProvider();
    }
  }

  ThemeMode get themeMode => _themeMode;

  /// Whether the app is currently painting dark, accounting for
  /// [ThemeMode.system] resolving against the platform setting.
  bool isDark(BuildContext context) {
    return switch (_themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      await _prefs?.setString(_storageKey, mode.name);
    } catch (e, s) {
      AppLogger.error('Could not save the theme preference', e, s);
    }
  }

  /// Flips between explicit light and dark, resolving [ThemeMode.system]
  /// against what is currently on screen so the first tap always visibly
  /// changes something.
  Future<void> toggle(BuildContext context) {
    return setThemeMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _decode(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
