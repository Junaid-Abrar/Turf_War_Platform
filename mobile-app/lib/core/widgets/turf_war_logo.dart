import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The Turf War mark.
///
/// Drawn rather than shipped as a PNG so it stays sharp at any size and picks
/// up the theme's colours — the same widget renders the splash mark, the login
/// header and (via `tool/generate_icons.dart`) the launcher icon source image.
///
/// The mark is a rounded green tile with pitch markings and a ball: readable at
/// 24px in an app bar and at 512px as a store icon.
class TurfWarLogo extends StatelessWidget {
  final double size;

  /// Forces the tile background instead of following the theme. Used by the
  /// icon generator, which must render the same on any platform.
  final bool alwaysDark;

  const TurfWarLogo({super.key, this.size = 72, this.alwaysDark = false});

  @override
  Widget build(BuildContext context) {
    final bool isDark = alwaysDark ||
        Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: TurfWarLogoPainter(alwaysDark: isDark),
      ),
    );
  }
}

/// Paints the mark.
///
/// Public because `tool/generate_icons.dart` drives it directly to rasterise
/// the launcher icon and splash artwork — the icon is then guaranteed to be the
/// same drawing the app shows, not a lookalike exported separately.
class TurfWarLogoPainter extends CustomPainter {
  /// Uses the dark palette (deep green tile, bright markings). The generator
  /// always passes true, since a launcher icon has no theme to follow.
  final bool alwaysDark;

  const TurfWarLogoPainter({required this.alwaysDark});

  Color get background => alwaysDark ? AppColors.brand900 : AppColors.brand500;
  Color get line => alwaysDark ? AppColors.brand400 : AppColors.brand100;
  Color get ball => alwaysDark ? AppColors.brand50 : AppColors.neutral0;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Rect bounds = Rect.fromLTWH(0, 0, s, s);

    // The tile.
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(s * 0.23)),
      Paint()..color = background,
    );

    // A single arc of the halfway line plus centre circle, cropped by the tile.
    // Detailed pitch markings were tried first and turn to mush at the 48px an
    // Android launcher actually renders — one arc still reads as a pitch and
    // survives the downscale.
    final Paint stroke = Paint()
      ..color = line.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(s * 0.23)),
    );
    canvas.drawCircle(Offset(s * 0.5, s * 1.02), s * 0.46, stroke);
    canvas.drawLine(
      Offset(0, s * 0.78),
      Offset(s, s * 0.78),
      stroke,
    );
    canvas.restore();

    // The monogram carries the identity. Letters stay legible at any size,
    // where fine linework does not.
    _paintMonogram(canvas, s);
  }

  /// Draws an interlocking "TW" centred on the tile.
  void _paintMonogram(Canvas canvas, double s) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: 'TW',
        style: TextStyle(
          color: ball,
          fontFamily: AppTypography.display,
          fontSize: s * 0.42,
          fontWeight: FontWeight.w800,
          // Outfit ships as a variable font. `fontWeight` alone picks the
          // nearest named instance, which for a single-file variable family is
          // Regular — the weight axis has to be set explicitly or the mark
          // rasterises thin.
          fontVariations: const <FontVariation>[FontVariation('wght', 800)],
          letterSpacing: -s * 0.02,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Sits slightly above centre: the arc below occupies the lower third, and
    // optically centring against it means nudging the type up.
    painter.paint(
      canvas,
      Offset(
        (s - painter.width) / 2,
        (s - painter.height) / 2 - s * 0.06,
      ),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(TurfWarLogoPainter oldDelegate) =>
      oldDelegate.alwaysDark != alwaysDark;
}
