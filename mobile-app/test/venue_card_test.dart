import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/venues/widgets/venue_card.dart';
import 'package:mobile_app/models/venue_model.dart';

void main() {
  const VenueModel venue = VenueModel(
    id: 'v1',
    name: 'Riverside Astro Pitch',
    description: 'Floodlit 5-a-side with a fresh 3G surface.',
    location: 'Camden, London',
    pricePerHour: 45,
    images: <String>[],
    amenities: <String>['Wifi', 'Parking'],
    ownerId: 'o1',
    averageRating: 4.5,
  );

  Widget host(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders name, location, price and rating', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(VenueCard(venue: venue, onTap: () {})),
    );

    expect(find.text('Riverside Astro Pitch'), findsOneWidget);
    expect(find.text('Camden, London'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    // The price is split into two TextSpans ("$45" + "/hr") inside one
    // Text.rich, so it is asserted as a substring of the rendered text rather
    // than an exact `find.text` match.
    final Text priceText = tester.widget<Text>(
      find.byWidgetPredicate(
        (Widget w) =>
            w is Text &&
            w.textSpan != null &&
            (w.textSpan!.toPlainText()).contains('45') &&
            w.textSpan!.toPlainText().contains('/hr'),
      ),
    );
    expect(priceText.textSpan!.toPlainText(), '\$45/hr');
  });

  testWidgets('does not render a rating pill when averageRating is zero', (
    WidgetTester tester,
  ) async {
    const VenueModel unrated = VenueModel(
      id: 'v2',
      name: 'New Pitch',
      description: '',
      location: 'Somewhere',
      pricePerHour: 20,
      images: <String>[],
      amenities: <String>[],
      ownerId: 'o1',
    );

    await tester.pumpWidget(host(VenueCard(venue: unrated, onTap: () {})));

    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('tapping the card invokes onTap', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      host(VenueCard(venue: venue, onTap: () => tapCount++)),
    );

    await tester.tap(find.byType(VenueCard));
    await tester.pump();

    expect(tapCount, 1);
  });
}
