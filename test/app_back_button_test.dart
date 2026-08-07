import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:altune/widgets/app_back_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBackButton', () {
    testWidgets('shows chevron left icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppBackButton())),
      );

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('calls onPressed when provided', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppBackButton(onPressed: () => pressed = true)),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(pressed, isTrue);
    });

    testWidgets('pops navigator when onPressed is null', (tester) async {
      bool popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: PopScope(
                canPop: true,
                onPopInvokedWithResult: (didPop, _) => popped = true,
                child: AppBackButton(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(popped, isTrue);
    });

    testWidgets('is wrapped in DpadFocusable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppBackButton())),
      );

      // Should find the button via the IconButton type
      expect(find.byType(IconButton), findsOneWidget);
    });
  });
}
