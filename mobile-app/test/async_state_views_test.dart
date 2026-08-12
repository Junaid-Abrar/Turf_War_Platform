import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/widgets/async_state_views.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  group('EmptyState', () {
    testWidgets('renders the title and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const EmptyState(
            icon: Icons.search_off,
            title: 'No matches',
            message: 'Nothing fits those filters.',
          ),
        ),
      );

      expect(find.text('No matches'), findsOneWidget);
      expect(find.text('Nothing fits those filters.'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('omits the message when none is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const EmptyState(icon: Icons.search_off, title: 'No matches')),
      );

      expect(find.text('No matches'), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });

  group('ErrorState', () {
    testWidgets('renders the message and a default title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const ErrorState(message: 'Could not reach the server.')),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Could not reach the server.'), findsOneWidget);
    });

    testWidgets('hides the retry button when onRetry is not given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const ErrorState(message: 'Could not reach the server.')),
      );

      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('shows a retry button that invokes onRetry when tapped', (
      WidgetTester tester,
    ) async {
      int retryCount = 0;
      await tester.pumpWidget(
        host(
          ErrorState(
            message: 'Could not reach the server.',
            onRetry: () => retryCount++,
          ),
        ),
      );

      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(retryCount, 1);
    });
  });
}
