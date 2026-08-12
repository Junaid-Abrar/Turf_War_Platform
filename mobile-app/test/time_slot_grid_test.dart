import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/bookings/widgets/time_slot_grid.dart';

void main() {
  const List<String> slots = <String>['09:00', '10:00', '11:00', '12:00'];

  SlotState stateFor(String slot) => switch (slot) {
        '09:00' => SlotState.past,
        '10:00' => SlotState.booked,
        '11:00' => SlotState.selected,
        _ => SlotState.available,
      };

  Widget host(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(height: 300, child: child),
      ),
    );
  }

  testWidgets('tapping an available slot calls onSelected with its label', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        TimeSlotGrid(
          slots: slots,
          stateFor: stateFor,
          onSelected: (String s) => selected = s,
        ),
      ),
    );

    await tester.tap(find.text('12:00'));
    await tester.pump();

    expect(selected, '12:00');
  });

  testWidgets('tapping a booked slot does not call onSelected', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        TimeSlotGrid(
          slots: slots,
          stateFor: stateFor,
          onSelected: (String s) => selected = s,
        ),
      ),
    );

    await tester.tap(find.text('10:00'));
    await tester.pump();

    expect(selected, isNull);
  });

  testWidgets('tapping a past slot does not call onSelected', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        TimeSlotGrid(
          slots: slots,
          stateFor: stateFor,
          onSelected: (String s) => selected = s,
        ),
      ),
    );

    await tester.tap(find.text('09:00'));
    await tester.pump();

    expect(selected, isNull);
  });

  testWidgets('enabled: false blocks taps on an otherwise-available slot', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        TimeSlotGrid(
          slots: slots,
          stateFor: stateFor,
          onSelected: (String s) => selected = s,
          enabled: false,
        ),
      ),
    );

    await tester.tap(find.text('12:00'));
    await tester.pump();

    expect(selected, isNull);
  });
}
