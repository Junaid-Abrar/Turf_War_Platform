import 'package:flutter/material.dart';

/// The app's colour palette.
///
/// Before Phase 5 the UI reached for `Colors.green`, `Colors.orange` and
/// `Colors.amber` directly at roughly a dozen call sites, which meant nothing
/// could be restyled centrally and dark mode was impossible. Every colour the
/// app paints now originates here.
///
/// Brand hues are a turf-green scale; the semantic entries below carry meaning
/// (a booking status, a rating) and are resolved through [AppSemanticColors] so
/// each one has a light and a dark value.
class AppColors {
  const AppColors._();

  // --- Brand scale -----------------------------------------------------------
  // Green because the product books grass pitches. The 500 step is the seed for
  // both ColorSchemes; the darker steps carry the dark theme's surfaces.
  static const Color brand50 = Color(0xFFECFDF3);
  static const Color brand100 = Color(0xFFD1FADF);
  static const Color brand200 = Color(0xFFA6F4C5);
  static const Color brand300 = Color(0xFF6CE9A6);
  static const Color brand400 = Color(0xFF32D583);
  static const Color brand500 = Color(0xFF16A34A);
  static const Color brand600 = Color(0xFF12833C);
  static const Color brand700 = Color(0xFF0E6631);
  static const Color brand800 = Color(0xFF0B4F27);
  static const Color brand900 = Color(0xFF0B1F17);

  /// Seed for `ColorScheme.fromSeed` in both brightnesses.
  static const Color seed = brand500;

  // --- Neutrals --------------------------------------------------------------
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF7F9F8);
  static const Color neutral100 = Color(0xFFEFF2F1);
  static const Color neutral200 = Color(0xFFE1E6E4);
  static const Color neutral400 = Color(0xFF9BA5A1);
  static const Color neutral600 = Color(0xFF5C6763);
  static const Color neutral800 = Color(0xFF232C29);
  static const Color neutral900 = Color(0xFF141A18);

  // --- Dark surfaces ---------------------------------------------------------
  // Material's generated dark surfaces come out noticeably purple against a
  // green primary. These are hand-picked neutrals with a faint green cast, so
  // the dark theme reads as the same product rather than a different one.
  static const Color darkSurfaceLowest = Color(0xFF0E1412);
  static const Color darkSurfaceLow = Color(0xFF171E1B);
  static const Color darkSurface = Color(0xFF1B2320);
  static const Color darkSurfaceHigh = Color(0xFF212A26);
  static const Color darkSurfaceHighest = Color(0xFF27312C);
  static const Color darkOnSurfaceVariant = Color(0xFFB6C0BB);
  static const Color darkOutline = Color(0xFF6E7A75);
  static const Color darkOutlineVariant = Color(0xFF3A4540);

  /// Page background behind the splash, matched by the native splash config in
  /// `pubspec.yaml` so there is no colour flash on launch.
  static const Color splashBackgroundLight = neutral50;
  static const Color splashBackgroundDark = brand900;

  // --- Status hues -----------------------------------------------------------
  // Each has a light-theme and a dark-theme variant: the light values are too
  // dark to read on a dark surface, and vice versa.
  static const Color successLight = Color(0xFF15803D);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color warningLight = Color(0xFFB45309);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color dangerLight = Color(0xFFB91C1C);
  static const Color dangerDark = Color(0xFFF87171);
  static const Color infoLight = Color(0xFF1D4ED8);
  static const Color infoDark = Color(0xFF60A5FA);
  static const Color ratingLight = Color(0xFFD97706);
  static const Color ratingDark = Color(0xFFFBBF24);
}

/// Colours that carry meaning rather than brand identity.
///
/// Registered as a [ThemeExtension] so a widget reads
/// `Theme.of(context).extension<AppSemanticColors>()!.success` and
/// automatically gets the right value for the active brightness — the same
/// mechanism `ColorScheme` uses, extended to concepts Material does not model
/// (a pending booking, a star rating).
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  /// A confirmed booking, a completed payment.
  final Color success;
  final Color onSuccessContainer;
  final Color successContainer;

  /// A pending booking, an unpaid balance.
  final Color warning;
  final Color onWarningContainer;
  final Color warningContainer;

  /// A cancelled booking. Distinct from `ColorScheme.error`, which is reserved
  /// for things that actually went wrong.
  final Color danger;
  final Color onDangerContainer;
  final Color dangerContainer;

  /// Neutral informational accent (demo-mode banner, hints).
  final Color info;
  final Color onInfoContainer;
  final Color infoContainer;

  /// Star fill in [RatingStars].
  final Color rating;

  /// Base colours for [ShimmerLoader]; the highlight sweeps across the base.
  final Color shimmerBase;
  final Color shimmerHighlight;

  const AppSemanticColors({
    required this.success,
    required this.onSuccessContainer,
    required this.successContainer,
    required this.warning,
    required this.onWarningContainer,
    required this.warningContainer,
    required this.danger,
    required this.onDangerContainer,
    required this.dangerContainer,
    required this.info,
    required this.onInfoContainer,
    required this.infoContainer,
    required this.rating,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColors.successLight,
    onSuccessContainer: Color(0xFF052E16),
    successContainer: Color(0xFFDCFCE7),
    warning: AppColors.warningLight,
    onWarningContainer: Color(0xFF451A03),
    warningContainer: Color(0xFFFEF3C7),
    danger: AppColors.dangerLight,
    onDangerContainer: Color(0xFF450A0A),
    dangerContainer: Color(0xFFFEE2E2),
    info: AppColors.infoLight,
    onInfoContainer: Color(0xFF172554),
    infoContainer: Color(0xFFDBEAFE),
    rating: AppColors.ratingLight,
    shimmerBase: AppColors.neutral200,
    shimmerHighlight: AppColors.neutral100,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: AppColors.successDark,
    onSuccessContainer: Color(0xFFDCFCE7),
    successContainer: Color(0xFF14532D),
    warning: AppColors.warningDark,
    onWarningContainer: Color(0xFFFEF3C7),
    warningContainer: Color(0xFF5C3A05),
    danger: AppColors.dangerDark,
    onDangerContainer: Color(0xFFFEE2E2),
    dangerContainer: Color(0xFF601B1B),
    info: AppColors.infoDark,
    onInfoContainer: Color(0xFFDBEAFE),
    infoContainer: Color(0xFF1E3A8A),
    rating: AppColors.ratingDark,
    shimmerBase: Color(0xFF243029),
    shimmerHighlight: Color(0xFF314037),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccessContainer,
    Color? successContainer,
    Color? warning,
    Color? onWarningContainer,
    Color? warningContainer,
    Color? danger,
    Color? onDangerContainer,
    Color? dangerContainer,
    Color? info,
    Color? onInfoContainer,
    Color? infoContainer,
    Color? rating,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      info: info ?? this.info,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      rating: rating ?? this.rating,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  /// Lets the theme animate between light and dark rather than snapping.
  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDangerContainer:
          Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

/// Sugar so widgets read `context.semanticColors.success` instead of the full
/// `Theme.of(context).extension<AppSemanticColors>()!` incantation.
extension SemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;
}
