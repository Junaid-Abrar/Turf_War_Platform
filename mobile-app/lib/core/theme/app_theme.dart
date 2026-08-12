import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the app's light and dark themes.
///
/// Both come from the same [_base] builder given a different [ColorScheme], so
/// a component styled once is styled in both brightnesses — the failure mode
/// this avoids is a control that looks right in light mode and unreadable in
/// dark because only one of two theme definitions was updated.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _base(_lightScheme, AppSemanticColors.light);
  static ThemeData get dark => _base(_darkScheme, AppSemanticColors.dark);

  /// Seeded from the brand green, then the surfaces are pinned to the neutral
  /// scale. `fromSeed` alone tints every surface faintly green, which at full
  /// screen size reads as a colour cast rather than a brand.
  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(seedColor: AppColors.seed).copyWith(
    primary: AppColors.brand500,
    onPrimary: AppColors.neutral0,
    primaryContainer: AppColors.brand100,
    onPrimaryContainer: AppColors.brand800,
    surface: AppColors.neutral0,
    onSurface: AppColors.neutral900,
    surfaceContainerLowest: AppColors.neutral0,
    surfaceContainerLow: AppColors.neutral50,
    surfaceContainer: AppColors.neutral50,
    surfaceContainerHigh: AppColors.neutral100,
    surfaceContainerHighest: AppColors.neutral100,
    onSurfaceVariant: AppColors.neutral600,
    outline: AppColors.neutral400,
    outlineVariant: AppColors.neutral200,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.brand400,
    onPrimary: AppColors.brand900,
    primaryContainer: AppColors.brand800,
    onPrimaryContainer: AppColors.brand100,
    surface: AppColors.neutral900,
    onSurface: AppColors.neutral50,
    surfaceContainerLowest: AppColors.darkSurfaceLowest,
    surfaceContainerLow: AppColors.darkSurfaceLow,
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurfaceHigh,
    surfaceContainerHighest: AppColors.darkSurfaceHighest,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
  );

  static ThemeData _base(ColorScheme colors, AppSemanticColors semantic) {
    final TextTheme text = AppTypography.textTheme(colors.onSurface);
    final bool isDark = colors.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: text,
      fontFamily: AppTypography.body,
      // Screens read semantic colours off this rather than importing the
      // palette directly, which is what makes dark mode automatic.
      extensions: <ThemeExtension<dynamic>>[semantic],

      // A shared axis slide on every push, replacing the platform default's
      // abrupt vertical slide on Android.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        // Keeps the status-bar icons legible against the app bar in both
        // brightnesses; without this Android picks light icons on a light bar.
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          // A hairline border instead of a shadow: at elevation 0 the card
          // still needs an edge to separate it from the page.
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: BorderSide(color: colors.outlineVariant),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: text.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: colors.outline),
        prefixIconColor: colors.onSurfaceVariant,
        suffixIconColor: colors.onSurfaceVariant,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerLow,
        selectedColor: colors.primaryContainer,
        checkmarkColor: colors.onPrimaryContainer,
        side: BorderSide(color: colors.outlineVariant),
        labelStyle: text.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: colors.outlineVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colors.primary, width: 2.5),
          insets: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
        circularTrackColor: Colors.transparent,
      ),

      splashFactory: InkSparkle.splashFactory,
    );
  }
}
