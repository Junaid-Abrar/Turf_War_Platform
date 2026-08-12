@Tags(<String>['tool'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/theme/app_typography.dart';
import 'package:mobile_app/core/widgets/turf_war_logo.dart';

/// Generates the launcher icon and splash artwork from the same painter the app
/// uses for its in-UI logo, so the icon can never drift from the mark shown on
/// the splash and login screens.
///
/// This lives as a test rather than a `flutter run` target because rasterising
/// needs a real Skia surface, and `flutter test` provides one headlessly — no
/// device, simulator or Xcode install required. It is tagged `tool` and skipped
/// by default (see `dart_test.yaml`) so CI does not rewrite committed assets;
/// regenerate deliberately with:
///
///   flutter test test/tool/generate_icons_test.dart --run-skipped
///
/// then rebuild the platform assets:
///
///   dart run flutter_launcher_icons
///   dart run flutter_native_splash:create
void main() {
  // The monogram is set in Outfit. `flutter test` ships no real fonts, so
  // without this the icon would rasterise in the placeholder font — visibly
  // wrong, and silently so.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final FontLoader loader = FontLoader(AppTypography.display)
      ..addFont(
        File('assets/fonts/Outfit.ttf')
            .readAsBytes()
            .then((Uint8List bytes) => bytes.buffer.asByteData()),
      );
    await loader.load();
  });

  test('generates app icon and splash artwork', () async {
    final Directory outputDir = Directory('assets/icon');
    await outputDir.create(recursive: true);

    // Full-bleed launcher icon: the mark fills the canvas, since iOS applies
    // its own corner mask.
    await _writeLogoPng(
      size: 1024,
      inset: 0,
      path: '${outputDir.path}/app_icon.png',
      background: AppColors.brand900,
    );

    // Android adaptive icons are cropped by the launcher's mask, which may be a
    // circle or a squircle, so the foreground layer insets the mark well inside
    // the safe zone rather than filling the canvas.
    await _writeLogoPng(
      size: 1024,
      inset: 220,
      path: '${outputDir.path}/app_icon_foreground.png',
      background: null,
    );

    // The native splash mark, transparent so it sits on whichever background
    // colour is configured for that brightness.
    await _writeLogoPng(
      size: 512,
      inset: 0,
      path: '${outputDir.path}/splash_logo.png',
      background: null,
    );

    expect(File('${outputDir.path}/app_icon.png').existsSync(), isTrue);
    expect(
      File('${outputDir.path}/app_icon_foreground.png').existsSync(),
      isTrue,
    );
    expect(File('${outputDir.path}/splash_logo.png').existsSync(), isTrue);
  });
}

/// Paints [TurfWarLogoPainter] onto a [size]x[size] canvas and writes a PNG.
///
/// The painter is driven directly rather than through the widget layer: there
/// is no layout to do, and a full off-screen render pipeline would be far more
/// machinery for the same pixels.
Future<void> _writeLogoPng({
  required double size,
  required double inset,
  required String path,
  required Color? background,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);

  if (background != null) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size, size),
      Paint()..color = background,
    );
  }

  final double markSize = size - inset * 2;
  canvas.save();
  canvas.translate(inset, inset);
  const TurfWarLogoPainter(alwaysDark: true)
      .paint(canvas, Size(markSize, markSize));
  canvas.restore();

  final ui.Image image =
      await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final ByteData? bytes =
      await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  if (bytes == null) throw StateError('Could not encode $path');
  await File(path).writeAsBytes(bytes.buffer.asUint8List());
}
