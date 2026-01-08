import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/pure_state.dart';

void main() {
  group('PureStateConfig', () {
    tearDown(() {
      PureStateConfig.reset();
    });

    test('defaults are correct', () {
      expect(PureStateConfig.enableHashCache, true);
    });

    test('reset restores defaults', () {
      PureStateConfig.enableHashCache = false;
      PureStateConfig.reset();
      expect(PureStateConfig.enableHashCache, true);
    });

    test('shallowEq respects enableHashCache = false', () {
      PureStateConfig.enableHashCache = false;

      final obj1 = [1, 2];
      final obj2 = [1, 2];

      // With HashCache disabled, shallowEq calls '=='
      // For Lists, '==' is identity check by default unless using listEquals, 
      // BUT shallowEq logic says:
      // if (!enableHashCache) return a == b;
      
      // Separate instances of lists are not equal with ==
      expect(PureEquality.shallowEq(obj1, obj2), false);
      expect(PureEquality.shallowEq(obj1, obj1), true);
    });

    test('shallowEq uses HashCache when enabled', () {
      PureStateConfig.enableHashCache = true;
      // We can't easily verify internal usage without mocking, 
      // but we can ensure it still behaves correctly.
      
       final obj1 = [1, 2];
       final obj2 = [1, 2];
       
       // Even with HashCache, different list instances have different identity hashes
       // so shallowEq usually returns false for different objects unless they are identicial.
       // HashCache just speeds up the specific case where hashes match but objects might differ (collisions).
       // Or checking if hashes DIFFER to return false early.
       
       expect(PureEquality.shallowEq(obj1, obj2), false);
    });
  });
}
