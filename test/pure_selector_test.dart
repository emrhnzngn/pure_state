import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/pure_state.dart';

class CounterState {
  final int count;
  final String message;
  
  CounterState({required this.count, required this.message});
}

void main() {
  group('PureSelector', () {
    late PureStore<CounterState> store;

    setUp(() {
      // Replace global cache with one that has NO timer
      PureEquality.debugReplaceGlobalCache(HashCache(autoClearInterval: null));
      
      store = PureStore<CounterState>(
        CounterState(count: 0, message: 'init'),
        batchDelay: Duration.zero,
      );
    });

    tearDown(() {
      store.dispose();
      // No need to dispose global cache explicitly if we replaced it with a safe one,
      // but good practice to clean up or reset.
    });

    testWidgets('rebuilds only when selected value changes', (tester) async {
      int buildCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: PureSelector<CounterState, int>(
            store: store,
            selector: (state) => state.count,
            builder: (context, count) {
              buildCount++;
              return Text('Count: $count');
            },
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);
      expect(buildCount, 1);

      // Update irrelevant part of state
      store.update((state) => CounterState(count: 0, message: 'updated'));
      await tester.pump(Duration(milliseconds: 20)); // Wait for batch delay
      
      // Should not rebuild
      expect(buildCount, 1);

      // Update relevant part
      store.update((state) => CounterState(count: 1, message: 'updated'));
      await tester.pump(Duration(milliseconds: 20)); // Wait for batch delay

      expect(find.text('Count: 1'), findsOneWidget);
      expect(buildCount, 2);
    });
  });
}
