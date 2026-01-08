import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/pure_state.dart';

void main() {
  group('PureEquality', () {
    test('shallowEq works for primitives', () {
      expect(PureEquality.shallowEq(1, 1), true);
      expect(PureEquality.shallowEq('a', 'a'), true);
      expect(PureEquality.shallowEq(1, 2), false);
    });

    test('shallowEq usage with HashCache', () {
      final obj1 = [1, 2];
      final obj2 = [1, 2];
      // Lists with same content have different identity, so shallowEq (which uses identity hash)
      // might return false if it relies solely on identity cache?
      // Let's check implementation. HashCache uses identityHashCode(obj) as key.
      // So different instances = different identity hashes usually.

      expect(PureEquality.shallowEq(obj1, obj1), true);
      // shallowEq checks hash first (which uses identityHashCode), then == operator
      // For different list instances, identityHashCode differs, so hash comparison fails
      // Even though obj1 == obj2 is true, shallowEq returns false due to different hashes
      expect(PureEquality.shallowEq(obj1, obj2), false);

      // Note: primitives generally share identity for small integers/strings in Dart VM but
      // objects don't.
    });

    test('deepEq compares collections correctly', () {
      final list1 = [
        1,
        2,
        {'a': 1},
      ];
      final list2 = [
        1,
        2,
        {'a': 1},
      ];
      final list3 = [
        1,
        2,
        {'a': 2},
      ];

      expect(PureEquality.deepEq(list1, list2), true);
      expect(PureEquality.deepEq(list1, list3), false);
    });

    setUp(() {
      PureEquality.debugReplaceGlobalCache(HashCache());
    });
  });
}
