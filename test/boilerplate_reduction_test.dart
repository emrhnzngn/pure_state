
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_state/pure_state.dart';

// Test State
class TestState {
  final int count;
  final String message;

  TestState({this.count = 0, this.message = ''});

  TestState copyWith({int? count, String? message}) {
    return TestState(
      count: count ?? this.count,
      message: message ?? this.message,
    );
  }
}

void main() {
  group('Boilerplate Reduction Tests', () {
    test('NamedAction should return correct name', () {
      final action = NamedAction<TestState>('TestAction', (state) => state);
      expect(action.name, 'TestAction');
      expect(action.toString(), 'TestAction');
    });

    test('store.mutate should update state correctly', () async {
      final store = PureStore<TestState>(TestState());
      
      store.mutate((state) => state.copyWith(count: 10), name: 'UpdateCount');
      
      // Wait for async processing
      await Future.delayed(Duration(milliseconds: 20));
      
      expect(store.state.count, 10);
      store.dispose();
    });

    test('store.mutate should work consistently with multiple updates', () async {
      final store = PureStore<TestState>(TestState());
      
      store.mutate((state) => state.copyWith(count: store.state.count + 1), name: 'Inc1');
      store.mutate((state) => state.copyWith(count: store.state.count + 1), name: 'Inc2');
      
      // Wait for async processing
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(store.state.count, 2);
      store.dispose();
    });
    
     test('NamedAction name is preserved in Middleware', () async {
      final store = PureStore<TestState>(TestState());
      String? capturedActionName;
      
      store.addMiddleware((store, action, next) {
        capturedActionName = action.name;
        next(action);
      });
      
      store.mutate((state) => state, name: 'DebugMe');
      
      await Future.delayed(Duration(milliseconds: 20));
      
      expect(capturedActionName, 'DebugMe');
      store.dispose();
    });
  });
}
