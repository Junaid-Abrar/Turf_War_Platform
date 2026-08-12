@Tags(<String>['tool'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/theme/app_typography.dart';
import 'package:mobile_app/core/widgets/widgets.dart';
import 'package:mobile_app/features/bookings/widgets/calendar_strip.dart';
import 'package:mobile_app/features/bookings/widgets/time_slot_grid.dart';
import 'package:mobile_app/features/venues/widgets/sport_category_row.dart';
import 'package:mobile_app/features/venues/widgets/venue_card.dart';
import 'package:mobile_app/models/venue_model.dart';

/// Renders the design system to PNGs under `build/screenshots/` so the theme
/// can be eyeballed in both brightnesses without booting a device.
///
/// Analysis passing proves the code compiles, not that the UI reads correctly —
/// this is the cheapest way to actually look at it. Tagged `tool` and skipped
/// by default (see `dart_test.yaml`); run it with:
///
///   flutter test test/tool/screenshots_test.dart --run-skipped
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFont(AppTypography.display, 'assets/fonts/Outfit.ttf');
    await _loadFont(AppTypography.body, 'assets/fonts/Inter.ttf');
  });

  testWidgets('renders the component gallery in light and dark',
      (WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    for (final (String name, ThemeData theme)
        in <(String, ThemeData)>[
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: const _Gallery(),
        ),
      );
      // Two pumps a second apart, never `pumpAndSettle`: the gallery contains
      // a shimmer skeleton whose animation repeats forever, so settling never
      // returns — but a single pump would catch every AnimatedContainer
      // mid-transition from its default colour, which misrepresents the theme.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      await _capture(tester, 'build/screenshots/gallery_$name.png');
    }
  });
}

Future<void> _loadFont(String family, String path) async {
  final FontLoader loader = FontLoader(family)
    ..addFont(
      File(path).readAsBytes().then((Uint8List b) => b.buffer.asByteData()),
    );
  await loader.load();
}

Future<void> _capture(WidgetTester tester, String path) async {
  final RenderRepaintBoundary boundary =
      tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );

  // Rasterising and PNG-encoding both hand work to the engine, which needs the
  // real event loop. Inside the default fake-async zone those futures never
  // complete and the test hangs rather than failing.
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Could not encode $path');

    final File file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
  });
}

/// One screen showing every design-system component together, which is where
/// inconsistencies between them become obvious.
class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    const VenueModel venue = VenueModel(
      id: 'v1',
      name: 'Riverside Astro Pitch',
      description: 'Floodlit 5-a-side with a fresh 3G surface.',
      location: 'Camden, London',
      pricePerHour: 45,
      images: <String>[],
      amenities: <String>['Wifi', 'Parking', 'Showers', 'Floodlights'],
      ownerId: 'o1',
      averageRating: 4.5,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Turf War')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Headline medium', style: theme.textTheme.headlineMedium),
          Text('Body medium sets the running text.',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          const Row(
            children: <Widget>[
              AppButton(label: 'Primary'),
              SizedBox(width: 8),
              AppButton(
                label: 'Secondary',
                variant: AppButtonVariant.secondary,
              ),
              SizedBox(width: 8),
              AppButton(label: 'Loading', isLoading: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              StatusBadge.forBookingStatus('confirmed'),
              const SizedBox(width: 8),
              StatusBadge.forBookingStatus('pending'),
              const SizedBox(width: 8),
              StatusBadge.forBookingStatus('cancelled'),
            ],
          ),
          const SizedBox(height: 16),
          const AppTextField(label: 'Email', prefixIcon: Icons.email_outlined),
          const SizedBox(height: 16),
          SportCategoryRow(
            selected: SportCategory.football,
            onSelected: (_) {},
          ),
          const SizedBox(height: 16),
          VenueCard(venue: venue, onTap: () {}),
          const RatingDistribution(
            ratings: <double>[5, 5, 4, 4, 3, 5, 2],
          ),
          const SizedBox(height: 16),
          CalendarStrip(selected: DateTime.now(), onSelected: (_) {}),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: TimeSlotGrid(
              slots: const <String>[
                '09:00',
                '10:00',
                '11:00',
                '12:00',
                '13:00',
                '14:00',
              ],
              stateFor: (String slot) => switch (slot) {
                '10:00' => SlotState.selected,
                '11:00' => SlotState.booked,
                '09:00' => SlotState.past,
                _ => SlotState.available,
              },
              onSelected: (_) {},
            ),
          ),
          const SizedBox(height: 16),
          const VenueCardSkeleton(),
          const SizedBox(height: 16),
          const SizedBox(
            height: 300,
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No matches',
              message: 'Nothing fits those filters.',
            ),
          ),
        ],
      ),
    );
  }
}
