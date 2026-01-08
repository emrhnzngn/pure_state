import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/pure_state.dart';

@immutable
class CounterState {
  const CounterState({required this.count});
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterState &&
          runtimeType == other.runtimeType &&
          count == other.count;

  @override
  int get hashCode => count.hashCode;
}

class IncrementAction extends PureAction<CounterState> {
  @override
  CounterState execute(CounterState state) {
    return CounterState(count: state.count + 1);
  }
}

class AsyncIncrementAction extends PureAction<CounterState> {
  @override
  Future<CounterState> execute(CounterState state) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return CounterState(count: state.count + 1);
  }
}

class AsyncErrorAction extends PureAction<CounterState> {
  @override
  Future<CounterState> execute(CounterState state) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    throw Exception('Async Test Error');
  }
}

class ErrorAction extends PureAction<CounterState> {
  @override
  CounterState execute(CounterState state) {
    throw Exception('Test Error');
  }
}

void main() {
  group('PureStore', () {
    late PureStore<CounterState> store;

    setUp(() {
      store = PureStore<CounterState>(
        const CounterState(count: 0),
        // Disable adaptive batching for predictable tests
        useAdaptiveBatchDelay: false,
        // Short batch delay for faster tests
        batchDelay: const Duration(milliseconds: 1),
      );
    });

    tearDown(() {
      store.dispose();
    });

    test('initial state is correct', () {
      expect(store.state.count, 0);
    });

    test('executes synchronous action correctly', () async {
      store.dispatch(IncrementAction());

      // Wait for state update (batch delay)
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(store.state.count, 1);
    });

    test('executes asynchronous action correctly', () async {
      store.dispatch(AsyncIncrementAction());

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(store.state.count, 1);
    });

    test('update method updates state', () async {
      store.update((state) => const CounterState(count: 10));

      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(store.state.count, 10);
    });

    test('emits state changes to stream', () async {
      final states = <CounterState>[];
      final subscription = store.stream.listen(states.add);

      store.dispatch(IncrementAction());
      await Future<void>.delayed(const Duration(milliseconds: 5));

      store.dispatch(IncrementAction());
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(states.length, 2);
      expect(states[0].count, 1);
      expect(states[1].count, 2);

      await subscription.cancel();
    });

    test('handles errors gracefully', () async {
      final errors = <Object>[];
      final subscription = store.errorStream.listen(errors.add);

      store.dispatch(ErrorAction());

      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(errors.isNotEmpty, true);
      expect(errors.first.toString(), contains('Test Error'));

      await subscription.cancel();
    });

    test('clears queue on error by default', () async {
      // Dispatch an async action that will fail
      store
        ..dispatch(AsyncErrorAction())
        // Immediately dispatch another action - this should be queued
        // but then removed when AsyncErrorAction fails
        ..dispatch(IncrementAction());

      // Wait long enough for error to happen and action to complete if it wasn't cleared
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Expect 0 because AsyncErrorAction failed (no state change)
      // AND IncrementAction was cleared (no state change)
      expect(store.state.count, 0);
    });

    test('dispose closes streams', () async {
      store
        ..dispose()
        // Attempting to dispatch after dispose should log warning but not throw
        ..dispatch(IncrementAction());
    });
  });
}
