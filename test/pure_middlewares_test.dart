import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/pure_state.dart';

// Test State
class TestState {
  TestState(this.count);
  final int count;
}

// Test Actions
class IncrementAction extends PureAction<TestState> {
  @override
  TestState execute(TestState state) => TestState(state.count + 1);
}

void main() {
  group('PureLogger', () {
    test('logs actions', () {
      final logs = <String>[];
      final logger = PureLogger<TestState>(
        printFunction: logs.add,
      );

      PureStore<TestState>(TestState(0))
        ..addMiddleware(logger.call)
        ..dispatch(IncrementAction());

      expect(logs.any((log) => log.contains('IncrementAction')), true);
    });
  });

  group('PureUndoRedo', () {
    test('manages history', () {
      final undoRedo = PureUndoRedo<TestState>();
      final initialState = TestState(0);

      undoRedo.record(initialState);

      final state1 = TestState(1);
      undoRedo.record(state1);

      final state2 = TestState(2);
      undoRedo.record(state2);

      expect(undoRedo.canUndo, true);

      final undoneState = undoRedo.undo(state2);
      expect(undoneState?.count, 1);

      final undoneState2 = undoRedo.undo(state1);
      expect(undoneState2?.count, 0);

      expect(undoRedo.canRedo, true);

      final redoneState = undoRedo.redo(initialState);
      expect(redoneState?.count, 1);
    });
  });

  group('PureThrottle', () {
    test('throttles actions', () async {
      final store = PureStore<TestState>(TestState(0));
      final throttle = PureThrottle<TestState>(
        const Duration(milliseconds: 100),
      );
      store
        ..addMiddleware(throttle.call)
        ..dispatch(IncrementAction())
        ..dispatch(IncrementAction()) // Should be throttled
        ..dispatch(IncrementAction()); // Should be throttled

      await Future<void>.delayed(Duration.zero);
      expect(store.state.count, 1);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      store.dispatch(IncrementAction()); // Should pass

      await Future<void>.delayed(Duration.zero);
      expect(store.state.count, 2);
    });
  });

  group('PureDebounce', () {
    test('debounces actions', () async {
      final store = PureStore<TestState>(TestState(0));
      final debounce = PureDebounce<TestState>(
        const Duration(milliseconds: 100),
      );
      store
        ..addMiddleware(debounce.call)
        ..dispatch(IncrementAction())
        ..dispatch(IncrementAction())
        ..dispatch(IncrementAction());

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(store.state.count, 0); // Not executed yet

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(store.state.count, 1); // Only last one executed
    });
  });
}
