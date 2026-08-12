// Golden tests for the design-system widget gallery.
//
// Unlike `test/tool/screenshots_test.dart` (which renders a full-app gallery
// to PNG purely for a human to eyeball), this asserts each widget's pixels
// against a committed reference via `matchesGoldenFile` — a regression fails
// the suite instead of requiring someone to notice a visual diff by eye.
//
// Regenerate after an intentional visual change with:
//   flutter test --update-goldens test/golden/
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/widgets/widgets.dart';

void main() {
  /// Pumps [child] under [theme] inside a fixed-size, non-animating host.
  ///
  /// Two pumps a second apart rather than `pumpAndSettle`: `ShimmerLoader`'s
  /// animation repeats forever, so settling would never return (the same trap
  /// documented in `screenshots_test.dart`). Two pumps land past every
  /// `AnimatedContainer`'s transition from its default colour without waiting
  /// on the shimmer to finish, which it never does.
  Future<void> pumpGallery(
    WidgetTester tester,
    ThemeData theme,
    Widget child, {
    Size size = const Size(400, 300),
  }) async {
    tester.view
      ..physicalSize = size * tester.view.devicePixelRatio
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  group('AppButton', () {
    Widget buttons() => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppButton(label: 'Primary'),
              SizedBox(height: 12),
              AppButton(
                label: 'Secondary',
                variant: AppButtonVariant.secondary,
              ),
              SizedBox(height: 12),
              AppButton(label: 'Loading', isLoading: true),
            ],
          ),
        );

    testWidgets('primary, secondary and loading in light mode', (
      WidgetTester tester,
    ) async {
      await pumpGallery(tester, AppTheme.light, buttons());
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/app_button_light.png'),
      );
    });

    testWidgets('primary, secondary and loading in dark mode', (
      WidgetTester tester,
    ) async {
      await pumpGallery(tester, AppTheme.dark, buttons());
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/app_button_dark.png'),
      );
    });
  });

  group('StatusBadge', () {
    Widget badges() => Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusBadge.forBookingStatus('confirmed'),
              StatusBadge.forBookingStatus('pending'),
              StatusBadge.forBookingStatus('cancelled'),
              StatusBadge.forBookingStatus('completed'),
              StatusBadge.forPaymentStatus('paid'),
            ],
          ),
        );

    testWidgets('one badge per status in light mode', (
      WidgetTester tester,
    ) async {
      await pumpGallery(tester, AppTheme.light, badges());
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/status_badge_light.png'),
      );
    });

    testWidgets('one badge per status in dark mode', (
      WidgetTester tester,
    ) async {
      await pumpGallery(tester, AppTheme.dark, badges());
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/status_badge_dark.png'),
      );
    });
  });

  group('RatingStars', () {
    Widget stars() => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RatingStars(rating: 4.5, showValue: true, reviewCount: 12),
              SizedBox(height: 8),
              RatingStars(rating: 0, showValue: true),
            ],
          ),
        );

    testWidgets('full, half and empty stars in light mode', (
      WidgetTester tester,
    ) async {
      await pumpGallery(tester, AppTheme.light, stars());
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/rating_stars_light.png'),
      );
    });
  });

  group('AppCard and AppTextField', () {
    Widget card() => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppCard(child: Text('A surface panel')),
              SizedBox(height: 12),
              AppTextField(label: 'Email', prefixIcon: Icons.email_outlined),
            ],
          ),
        );

    testWidgets('card and text field in light mode', (
      WidgetTester tester,
    ) async {
      await pumpGallery(tester, AppTheme.light, card());
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/app_card_text_field_light.png'),
      );
    });

    testWidgets('card and text field in dark mode', (
      WidgetTester tester,
    ) async {
      await pumpGallery(tester, AppTheme.dark, card());
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/app_card_text_field_dark.png'),
      );
    });
  });

  group('TurfWarLogo', () {
    testWidgets('renders the mark in light mode', (WidgetTester tester) async {
      await pumpGallery(
        tester,
        AppTheme.light,
        const Padding(
          padding: EdgeInsets.all(16),
          child: TurfWarLogo(size: 72),
        ),
        size: const Size(120, 120),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/turf_war_logo_light.png'),
      );
    });

    testWidgets('renders the mark in dark mode', (WidgetTester tester) async {
      await pumpGallery(
        tester,
        AppTheme.dark,
        const Padding(
          padding: EdgeInsets.all(16),
          child: TurfWarLogo(size: 72),
        ),
        size: const Size(120, 120),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/turf_war_logo_dark.png'),
      );
    });
  });

  group('ShimmerLoader', () {
    testWidgets('renders a skeleton block frozen mid-animation', (
      WidgetTester tester,
    ) async {
      await pumpGallery(
        tester,
        AppTheme.light,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerLoader(
            child: ShimmerBox(width: 200, height: 60),
          ),
        ),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/shimmer_loader_light.png'),
      );
    });
  });
}
