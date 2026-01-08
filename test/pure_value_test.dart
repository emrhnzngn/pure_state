import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/src/pure_value.dart';

void main() {
  group('PureValue', () {
    test('initial value is set correctly', () {
      final value = PureValue<int>(42);
      expect(value.value, 42);
    });

    test('update modulates the value', () {
      final value = PureValue<int>(0)..update((val) => val + 1);
      expect(value.value, 1);
    });

    test('set updates the value', () {
      final value = PureValue<String>('initial')..value = 'defined';
      expect(value.value, 'defined');
    });

    test('listeners are notified on change', () {
      final value = PureValue<int>(0);
      var notificationCount = 0;

      value
        ..addListener(() {
          notificationCount++;
        })
        ..value = 1;
      expect(notificationCount, 1);

      value.update((val) => val + 1);
      expect(notificationCount, 2);
    });
  });
}
