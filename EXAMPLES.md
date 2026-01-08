# Pure State Examples

This document provides comprehensive examples of all Pure State features.

## Table of Contents

- [Pure State Examples](#pure-state-examples)
  - [Table of Contents](#table-of-contents)
  - [Basic Usage](#basic-usage)
    - [Simple Counter](#simple-counter)
  - [AsyncValue](#asyncvalue)
  - [Family Pattern](#family-pattern)
  - [Auto-Dispose Stores](#auto-dispose-stores)
  - [Action Authorization](#action-authorization)
  - [State Validation](#state-validation)
  - [Retryable Actions](#retryable-actions)
  - [Computed Selectors](#computed-selectors)
  - [Batching Actions](#batching-actions)
  - [Time-Travel Debugging](#time-travel-debugging)
  - [Testing](#testing)
    - [Store Testing](#store-testing)
    - [Widget Testing](#widget-testing)
    - [Golden Testing](#golden-testing)
  - [Performance Tips](#performance-tips)
  - [Best Practices](#best-practices)

---

## Basic Usage

### Simple Counter

```dart
// 1. Define your state
class CounterState {
  final int count;
  const CounterState({required this.count});
  
  CounterState copyWith({int? count}) {
    return CounterState(count: count ?? this.count);
  }
}

// 2. Create actions
class IncrementAction extends PureAction<CounterState> {
  @override
  CounterState execute(CounterState state) {
    return state.copyWith(count: state.count + 1);
  }
}

// 3. Create store
final counterStore = PureStore<CounterState>(
  const CounterState(count: 0),
);

// 4. Use in widgets
PureBuilder<CounterState>(
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)

// 5. Dispatch actions
counterStore.dispatch(IncrementAction());

// Or use shorthand
counterStore.mutate((s) => s.copyWith(count: s.count + 1));
```

---

## AsyncValue

Handle async operations elegantly:

```dart
class UserState {
  final AsyncValue<User> user;
  const UserState({required this.user});
}

// Action to fetch user
class FetchUserAction extends PureAction<UserState> {
  @override
  Future<UserState> execute(UserState state) async {
    try {
      final user = await api.fetchUser();
      return UserState(user: AsyncData(user));
    } catch (e, stack) {
      return UserState(user: AsyncError(e, stack));
    }
  }
}

// Widget usage
PureBuilder<UserState>(
  builder: (context, state) {
    return state.user.when(
      data: (user) => Text('Hello, ${user.name}!'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  },
)

// Or use maybeWhen for default handling
state.user.maybeWhen(
  data: (user) => UserProfile(user),
  orElse: () => Placeholder(),
);
```

---

## Family Pattern

Create parameterized stores:

```dart
// Create a family for user stores
final userStoreFamily = PureStoreFamily<UserState, int>(
  (userId) => PureStore(UserState(id: userId)),
);

// Get store for user 42
final user42Store = userStoreFamily(42);

// Get store for user 100
final user100Store = userStoreFamily(100);

// Same ID returns same instance
assert(identical(userStoreFamily(42), user42Store));

// Dispose specific user store
userStoreFamily.dispose(42);

// Dispose all
userStoreFamily.disposeAll();

// Multiple parameters
final chatStoreFamily = PureStoreFamily2<ChatState, String, int>(
  (roomId, userId) => PureStore(
    ChatState(roomId: roomId, userId: userId),
  ),
);

final chatStore = chatStoreFamily.call2('room-1', 42);
```

---

## Auto-Dispose Stores

Automatically clean up unused stores:

```dart
// Store that disposes after 5 minutes of no listeners
final tempStore = PureAutoDisposeStore<TempState>(
  TempState(),
  keepAliveFor: Duration(minutes: 5),
  onAutoDispose: () => print('Store auto-disposed'),
);

// Use listenTracked for auto-dispose support
final subscription = tempStore.listenTracked((state) {
  print('State: $state');
});

// After cancelling subscription and waiting 5 minutes,
// store automatically disposes
subscription.cancel();

// Prevent auto-disposal
tempStore.keepAlive();

// Time-to-live store (fixed duration)
final ttlStore = PureTTLStore<State>(
  State(),
  ttl: Duration(hours: 1),
  onExpire: () => print('Store expired'),
);
```

---

## Action Authorization

Protect actions with authorization:

```dart
class DeleteUserAction extends PureAuthorizedAction<AppState> {
  final int userId;
  DeleteUserAction(this.userId);
  
  @override
  bool authorize(AppState state) {
    // Only admins can delete users
    return state.currentUser.role == UserRole.admin;
  }
  
  @override
  AppState executeAuthorized(AppState state) {
    return state.copyWith(
      users: state.users.where((u) => u.id != userId).toList(),
    );
  }
  
  @override
  AppState onUnauthorized(AppState state) {
    // Custom unauthorized handling
    showError('You do not have permission');
    return state;
  }
}
```

---

## State Validation

Ensure state is always valid:

```dart
// Make your state validatable
class UserFormState with ValidatableState {
  final String email;
  final int age;
  
  const UserFormState({required this.email, required this.age});
  
  @override
  ValidationResult validate() {
    final errors = <String>[];
    
    if (!email.contains('@')) {
      errors.add('Invalid email format');
    }
    
    if (age < 0 || age > 150) {
      errors.add('Age must be between 0 and 150');
    }
    
    return ValidationResult(errors);
  }
}

// Actions automatically validate
class UpdateEmailAction extends PureValidatedAction<UserFormState> {
  final String newEmail;
  UpdateEmailAction(this.newEmail);
  
  @override
  UserFormState executeWithoutValidation(UserFormState state) {
    return UserFormState(email: newEmail, age: state.age);
  }
  // Throws StateValidationException if invalid
}

// Add validation middleware to all actions
store.addMiddlewareWithResult(
  validationMiddleware<UserFormState>(
    onValidationError: (errors) => print('Validation failed: $errors'),
  ),
);
```

---

## Retryable Actions

Auto-retry failed operations:

```dart
class FetchDataAction extends PureRetryableAction<AppState> {
  @override
  int get maxRetries => 3;
  
  @override
  Duration get retryDelay => Duration(seconds: 1);
  
  @override
  bool shouldRetry(Object error) {
    // Only retry on network errors
    return error is NetworkException;
  }
  
  @override
  Future<AppState> executeWithRetry(AppState state) async {
    final data = await api.fetchData();
    return state.copyWith(data: data);
  }
  
  @override
  void onRetry(int attempt, Object error) {
    print('Retry attempt $attempt: $error');
  }
}

// Exponential backoff
class FetchWithBackoffAction extends PureExponentialBackoffAction<AppState> {
  @override
  Duration get baseDelay => Duration(seconds: 1);
  
  @override
  Duration get maxDelay => Duration(seconds: 60);
  
  @override
  double get backoffMultiplier => 2.0;
  
  @override
  Future<AppState> executeWithRetry(AppState state) async {
    // Implementation
  }
}
```

---

## Computed Selectors

Derive state from multiple stores:

```dart
// Two stores
PureComputedSelector2<UserState, SettingsState, String>(
  store1: userStore,
  store2: settingsStore,
  selector: (user, settings) => 
    '${user.name} - ${settings.theme}',
  builder: (context, computed) => Text(computed),
)

// Three stores
PureComputedSelector3<UserState, CartState, SettingsState, Widget>(
  store1: userStore,
  store2: cartStore,
  store3: settingsStore,
  selector: (user, cart, settings) {
    return CartSummary(
      userName: user.name,
      itemCount: cart.items.length,
      currency: settings.currency,
    );
  },
  builder: (context, widget) => widget,
)

// Dynamic number of stores
PureComputedSelectorN<String>(
  stores: [userStore, settingsStore, cartStore],
  selector: (states) {
    final user = states[0] as UserState;
    final settings = states[1] as SettingsState;
    final cart = states[2] as CartState;
    return 'Summary: ${user.name}, ${cart.items.length} items';
  },
  builder: (context, text) => Text(text),
)

// Non-widget computed values
final computed = ComputedValue2(
  store1: userStore,
  store2: settingsStore,
  compute: (user, settings) => '${user.name} - ${settings.theme}',
);

computed.listen((value) => print('Computed: $value'));
```

---

## Batching Actions

Execute multiple actions with one state update:

```dart
// Batch multiple actions
await store.batch(() {
  dispatch(Action1());
  dispatch(Action2());
  dispatch(Action3());
}); // Only one state update emitted

// Get final state after batch
final finalState = await store.batchAndGet(() {
  dispatch(IncrementAction());
  dispatch(IncrementAction());
  dispatch(IncrementAction());
});
print('Count after batch: ${finalState.count}');
```

---

## Time-Travel Debugging

Replay and inspect state history:

```dart
// Enable replay
store.enableReplay(maxHistory: 100);

// Go back 5 states
store.replayBack(steps: 5);

// Go to specific index
store.replay(toIndex: 10);

// Find and replay to matching state
store.replayToWhere((state) => state.userId == 42);

// Get history
final history = store.getHistorySnapshot();

// Advanced recording
final recorder = PureStateRecorder<MyState>();
store.attachRecorder(recorder);

// Analyze recordings
final transitions = recorder.findByAction('IncrementAction');
final recentChanges = recorder.findByTimeRange(
  start: DateTime.now().subtract(Duration(hours: 1)),
  end: DateTime.now(),
);
```

---

## Testing

### Store Testing

```dart
// BLoC-style testing
await PureTestUtils.storeTest<CounterState>(
  description: 'increments counter',
  build: () => PureStore(CounterState(count: 0)),
  act: (store) => store.dispatch(IncrementAction()),
  expect: () => [CounterState(count: 1)],
);

// Mock stores
final mockStore = PureTestUtils.createMockStore<int>(
  initialState: 0,
  emittedStates: [1, 2, 3],
  emitDelay: Duration(milliseconds: 100),
);

// Snapshot testing
await PureTestUtils.expectStateSnapshot(
  state,
  'test/snapshots/my_state.json',
  toJson: (s) => s.toJson(),
);

// Wait for conditions
await PureTestUtils.waitForCondition(
  store,
  (state) => state.isReady,
);

// Capture timeline
final timeline = await PureTestUtils.captureTimeline(
  store,
  duration: Duration(seconds: 2),
);
```

### Widget Testing

```dart
testWidgets('counter increments', (tester) async {
  await tester.pumpPureState(
    store: counterStore,
    child: CounterWidget(),
  );
  
  await tester.dispatchAndPump(
    store: counterStore,
    action: IncrementAction(),
  );
  
  expect(find.text('1'), findsOneWidget);
});

// Test scenario
testWidgets('complex scenario', (tester) async {
  final scenario = await PureWidgetTest.setup(
    tester: tester,
    store: counterStore,
    widget: CounterApp(),
  );
  
  await scenario.dispatch(IncrementAction());
  await scenario.waitFor(find.text('1'));
  
  expect(scenario.store.state.count, 1);
  
  await scenario.teardown();
});
```

### Golden Testing

```dart
testWidgets('counter golden test', (tester) async {
  await PureGoldenTest.testWithStore(
    tester: tester,
    store: PureStore(CounterState(count: 42)),
    widget: CounterWidget(),
    goldenFile: 'goldens/counter_42.png',
  );
});

// Test multiple states
await PureGoldenTest.testMultipleStates(
  tester: tester,
  states: [
    CounterState(count: 0),
    CounterState(count: 42),
    CounterState(count: 100),
  ],
  widget: (state) => CounterWidget(),
  goldenFile: (index, state) => 'counter_${state.count}.png',
);

// Test with actions
await PureGoldenTest.testWithActions(
  tester: tester,
  initialState: CounterState(count: 0),
  actions: [IncrementAction(), IncrementAction()],
  widget: CounterWidget(),
  goldenFile: 'counter_after_increments.png',
);
```

---

## Performance Tips

1. **Use Selectors**: Avoid full rebuilds with `PureSelector`
2. **Batch Actions**: Use `batch()` for multiple updates
3. **Sampling Equality**: Automatically enabled for large collections
4. **Priority Actions**: Set higher priority for UI-critical updates
5. **Auto-Dispose**: Clean up unused stores automatically
6. **Debounce/Throttle**: Use built-in action debouncing
7. **Memoization**: Selectors are automatically memoized

---

## Best Practices

1. **Immutable State**: Always use immutable state classes
2. **CopyWith**: Implement copyWith for all state classes
3. **Validation**: Use ValidatableState for form states
4. **Authorization**: Protect sensitive actions
5. **Testing**: Write tests for all actions
6. **Error Handling**: Use try-catch in async actions
7. **Dispose**: Always dispose stores when done

---

For more examples, check the [example](example/) directory.

