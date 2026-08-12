import 'package:flutter/material.dart';

/// The app's type scale.
///
/// Two families, each with one job: **Outfit** is a geometric display face used
/// only for headlines and the wordmark, **Inter** carries every piece of running
/// text and UI label. Both are bundled in `assets/fonts/` (see `pubspec.yaml`)
/// rather than pulled at runtime, so first launch has no font pop-in.
class AppTypography {
  const AppTypography._();

  /// Headlines and display text.
  static const String display = 'Outfit';

  /// Body copy, labels, buttons, input text.
  static const String body = 'Inter';

  /// Both families are shipped as **variable** fonts — one file spanning every
  /// weight. Flutter matches `fontWeight` against a font's *named instances*,
  /// and a single-file variable family exposes only one, so a bare
  /// `fontWeight: w700` silently renders Regular. Setting the `wght` axis
  /// alongside it is what actually moves the weight.
  ///
  /// Every style below therefore goes through this helper rather than setting
  /// `fontWeight` directly.
  static List<FontVariation> _weight(FontWeight weight) {
    return <FontVariation>[FontVariation('wght', weight.value.toDouble())];
  }

  /// Builds the full [TextTheme] for a brightness.
  ///
  /// Sizes come from Material 3's scale; what changes here is the family split,
  /// slightly tighter tracking on the display sizes (geometric faces read loose
  /// at large sizes by default), and a taller line height on body text.
  static TextTheme textTheme(Color onSurface) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: display,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        fontVariations: _weight(FontWeight.w800),
        letterSpacing: -1,
        height: 1.1,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: display,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        fontVariations: _weight(FontWeight.w700),
        letterSpacing: -0.8,
        height: 1.15,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: display,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        fontVariations: _weight(FontWeight.w700),
        letterSpacing: -0.5,
        height: 1.2,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontFamily: display,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        fontVariations: _weight(FontWeight.w700),
        letterSpacing: -0.4,
        height: 1.25,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: display,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontVariations: _weight(FontWeight.w700),
        letterSpacing: -0.3,
        height: 1.3,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: display,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontVariations: _weight(FontWeight.w600),
        letterSpacing: -0.2,
        height: 1.3,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: display,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontVariations: _weight(FontWeight.w600),
        letterSpacing: -0.1,
        height: 1.35,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: body,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontVariations: _weight(FontWeight.w600),
        height: 1.4,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: body,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontVariations: _weight(FontWeight.w600),
        height: 1.4,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: body,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontVariations: _weight(FontWeight.w400),
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: body,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontVariations: _weight(FontWeight.w400),
        height: 1.5,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: body,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontVariations: _weight(FontWeight.w400),
        height: 1.45,
        color: onSurface,
      ),
      labelLarge: TextStyle(
        fontFamily: body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontVariations: _weight(FontWeight.w600),
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: body,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontVariations: _weight(FontWeight.w500),
        letterSpacing: 0.2,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontFamily: body,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontVariations: _weight(FontWeight.w600),
        letterSpacing: 0.4,
        color: onSurface,
      ),
    );
  }

  /// The wordmark treatment, used on the splash and the login header.
  static const TextStyle wordmark = TextStyle(
    fontFamily: display,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    // Written out rather than via `_weight` because this is a const.
    fontVariations: <FontVariation>[FontVariation('wght', 800)],
    letterSpacing: 4,
  );

  /// Tabular figures for prices and times, so digits do not shift width as a
  /// total animates or a countdown ticks.
  static const TextStyle numeric = TextStyle(
    fontFamily: body,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
}
