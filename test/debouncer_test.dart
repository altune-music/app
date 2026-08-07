import 'package:altune/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('executes action after delay', () async {
      var callCount = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

      debouncer(() => callCount++);

      expect(callCount, 0);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);

      debouncer.dispose();
    });

    test('cancels previous pending action on repeated calls', () async {
      var callCount = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

      debouncer(() => callCount++);
      debouncer(() => callCount++);

      await Future.delayed(const Duration(milliseconds: 150));
      // Only the last scheduled action should fire.
      expect(callCount, 1);

      debouncer.dispose();
    });

    test('cancel prevents pending action from executing', () async {
      var callCount = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

      debouncer(() => callCount++);
      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 0);

      debouncer.dispose();
    });

    test('dispose cancels pending action', () async {
      var callCount = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

      debouncer(() => callCount++);
      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 0);
    });

    test('uses default 300ms delay when none provided', () async {
      var callCount = 0;
      final debouncer = Debouncer();

      debouncer(() => callCount++);

      await Future.delayed(const Duration(milliseconds: 250));
      expect(callCount, 0);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 1);

      debouncer.dispose();
    });
  });
}
