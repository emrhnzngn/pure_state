import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/pure_state.dart';

class TestState {}

class NormalAction extends PureAction<TestState> {
  @override
  int get priority => 0;
  
  @override
  TestState execute(TestState state) => state;
}

class HighPriorityAction extends PureAction<TestState> {
  @override
  int get priority => 10;

  @override
  TestState execute(TestState state) => state;
}

class LowPriorityAction extends PureAction<TestState> {
  @override
  int get priority => -10;

  @override
  TestState execute(TestState state) => state;
}

void main() {
  group('PurePriorityQueue', () {
    // Note: PurePriorityQueue is internal, but we can test its effect via store dispatch
    // or by accessing it if we export it or make it visible for testing. 
    // Since we export 'src/pure_priority_queue.dart' in library (via pure_state.dart -> export), access might require explicit import if not exported by main package file properly?
    // Checking pure_state.dart, it exports 'src/pure_priority_queue.dart' line 13 says "Priority-based action queue" but I don't see it exported in export list.
    // Let me check 'lib/pure_state.dart' again.
    // It DOES NOT export 'src/pure_priority_queue.dart'. It only imports it in pure_store.dart.
    // So we test priority via Store behavior.

    late PureStore<List<String>> store;

    setUp(() {
      store = PureStore<List<String>>(
         [],
         useAdaptiveBatchDelay: false,
         batchDelay: Duration(milliseconds: 100), // Long delay to batch actions up
      );
    });
    
    tearDown(() {
      store.dispose();
    });

    test('executes actions in priority order', () async {
      // Dispatch a slow action to block the queue processing
      store.dispatch(ActionWithDelay('slow', Duration(milliseconds: 50), priority: 0));
      
      // Dispatch mixed priority actions immediately after
      store.dispatch(LoggingAction('normal', priority: 0));
      store.dispatch(LoggingAction('high', priority: 10));
      store.dispatch(LoggingAction('low', priority: -10));
      store.dispatch(LoggingAction('critical', priority: 100));

      // Wait for all to complete
      await Future.delayed(Duration(milliseconds: 500));

      // Expected order:
      // 1. slow (started immediately)
      // 2. critical (100)
      // 3. high (10)
      // 4. normal (0)
      // 5. low (-10)
      
      final state = store.state;
      expect(state.length, 5);
      expect(state[0], 'slow');
      expect(state[1], 'critical');
      expect(state[2], 'high');
      expect(state[3], 'normal');
      expect(state[4], 'low');
    });
  });
}

class ActionWithDelay extends PureAction<List<String>> {
  final String name;
  final Duration delay;
  final int _priority;

  ActionWithDelay(this.name, this.delay, {int priority = 0}) : _priority = priority;

  @override
  int get priority => _priority;

  @override
  Future<List<String>> execute(List<String> state) async {
    await Future.delayed(delay);
    return [...state, name];
  }
}

class LoggingAction extends PureAction<List<String>> {
  final String name;
  final int _priority;

  LoggingAction(this.name, {int priority = 0}) : _priority = priority;

  @override
  int get priority => _priority;

  @override
  List<String> execute(List<String> state) {
    return [...state, name];
  }
}
