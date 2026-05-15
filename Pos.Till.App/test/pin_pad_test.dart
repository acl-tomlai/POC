import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_till_app/widgets/pin_pad.dart';

Future<void> _pumpPad(
  WidgetTester tester, {
  required ValueChanged<String> onComplete,
  String? errorText,
  bool enabled = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PinPad(
          onComplete: onComplete,
          errorText: errorText,
          enabled: enabled,
        ),
      ),
    ),
  );
}

Future<void> _tapDigit(WidgetTester tester, String d) async {
  await tester.tap(find.widgetWithText(OutlinedButton, d));
  await tester.pump();
}

void main() {
  group('PinPad', () {
    testWidgets('fires onComplete with the 4-digit string', (WidgetTester tester) async {
      String? captured;
      await _pumpPad(
        tester,
        onComplete: (String pin) => captured = pin,
      );

      for (final String d in <String>['1', '2', '3', '4']) {
        await _tapDigit(tester, d);
      }
      expect(captured, '1234');
    });

    testWidgets('extra digits past length are ignored', (WidgetTester tester) async {
      final List<String> calls = <String>[];
      await _pumpPad(
        tester,
        onComplete: calls.add,
      );

      for (final String d in <String>['1', '2', '3', '4', '5', '6']) {
        await _tapDigit(tester, d);
      }
      // onComplete fires exactly once at length=4, even if more taps follow.
      expect(calls, <String>['1234']);
    });

    testWidgets('errorText resets the entered digits', (WidgetTester tester) async {
      final List<String> calls = <String>[];
      await _pumpPad(
        tester,
        onComplete: calls.add,
      );

      await _tapDigit(tester, '9');
      await _tapDigit(tester, '8');
      await _tapDigit(tester, '7');
      await _tapDigit(tester, '6');
      expect(calls, <String>['9876']);

      // Parent surfaces a wrong-PIN error → pad clears.
      await _pumpPad(
        tester,
        onComplete: calls.add,
        errorText: 'Wrong PIN.',
      );
      expect(find.text('Wrong PIN.'), findsOneWidget);

      await _tapDigit(tester, '1');
      await _tapDigit(tester, '1');
      await _tapDigit(tester, '1');
      await _tapDigit(tester, '1');
      expect(calls.last, '1111');
    });

    testWidgets('disabled state ignores taps', (WidgetTester tester) async {
      final List<String> calls = <String>[];
      await _pumpPad(
        tester,
        onComplete: calls.add,
        enabled: false,
      );

      for (final String d in <String>['1', '2', '3', '4']) {
        await _tapDigit(tester, d);
      }
      expect(calls, isEmpty);
    });
  });
}
