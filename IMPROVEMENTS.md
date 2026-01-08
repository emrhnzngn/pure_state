# Pure State v1.1.0 - Major Improvements

## 🎉 What's New

Pure State has been significantly enhanced with production-ready features while maintaining **zero external dependencies**.

---

## ✨ New Features

### 1. **AsyncValue Wrapper** 🔄
Elegant handling of async operations inspired by Riverpod but implemented purely in Dart.

```dart
AsyncValue<User> user = await AsyncValue.guard(() => api.fetchUser());

user.when(
  data: (user) => Text(user.name),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => ErrorWidget(err),
);
```

**Benefits:**
- Clean async state representation
- Type-safe pattern matching
- Zero boilerplate

---

### 2. **Family Pattern** 👨‍👩‍👧‍👦
Create parameterized stores for dynamic scenarios.

```dart
final userStoreFamily = PureStoreFamily<UserState, int>(
  (userId) => PureStore(UserState(id: userId)),
);

final user42Store = userStoreFamily(42);
final user100Store = userStoreFamily(100);
```

**Use Cases:**
- User-specific stores
- List item stores
- Filtered data stores
- Multi-tenant applications

---

### 3. **Auto-Dispose Stores** 🗑️
Prevent memory leaks with automatic cleanup.

```dart
final autoStore = PureAutoDisposeStore<State>(
  initialState,
  keepAliveFor: Duration(minutes: 5),
  onAutoDispose: () => print('Cleaned up!'),
);
```

**Variants:**
- `PureAutoDisposeStore`: Listener-based disposal
- `PureTTLStore`: Time-based disposal

---

### 4. **Action Authorization** 🔐
Protect sensitive operations with built-in authorization.

```dart
class DeleteUserAction extends PureAuthorizedAction<AppState> {
  @override
  bool authorize(AppState state) =>
      state.currentUser.role == UserRole.admin;
      
  @override
  AppState executeAuthorized(AppState state) {
    // Delete user logic
  }
}
```

---

### 5. **State Validation** ✅
Ensure state integrity with automatic validation.

```dart
class UserFormState with ValidatableState {
  @override
  ValidationResult validate() {
    final errors = <String>[];
    if (!email.contains('@')) errors.add('Invalid email');
    return ValidationResult(errors);
  }
}

// Actions automatically validate
class UpdateEmailAction extends PureValidatedAction<UserFormState> {
  // Throws StateValidationException if invalid
}
```

---

### 6. **Retryable Actions** 🔄
Built-in retry logic with exponential backoff.

```dart
class FetchDataAction extends PureRetryableAction<AppState> {
  @override
  int get maxRetries => 3;
  
  @override
  Duration get retryDelay => Duration(seconds: 1);
  
  @override
  bool shouldRetry(Object error) => error is NetworkException;
}

// Or use exponential backoff
class FetchWithBackoffAction extends PureExponentialBackoffAction<AppState> {
  // Automatic exponential backoff strategy
}
```

---

### 7. **Computed Selectors** 🔗
Derive state from multiple stores efficiently.

```dart
// Two stores
PureComputedSelector2<UserState, SettingsState, String>(
  store1: userStore,
  store2: settingsStore,
  selector: (user, settings) => '${user.name} - ${settings.theme}',
  builder: (context, computed) => Text(computed),
)

// Three stores
PureComputedSelector3<T1, T2, T3, R>(...)

// Dynamic number of stores
PureComputedSelectorN<R>(
  stores: [store1, store2, store3],
  selector: (states) => compute(states),
  builder: (context, result) => Widget(),
)

// Non-widget computed values
final computed = ComputedValue2(
  store1: userStore,
  store2: settingsStore,
  compute: (user, settings) => derivedValue,
);
```

---

### 8. **Enhanced Testing** 🧪

#### BLoC-Style Store Testing
```dart
await PureTestUtils.storeTest<CounterState>(
  description: 'increments counter',
  build: () => PureStore(CounterState(count: 0)),
  act: (store) => store.dispatch(IncrementAction()),
  expect: () => [CounterState(count: 1)],
);
```

#### Mock Stores
```dart
final mockStore = PureTestUtils.createMockStore<int>(
  initialState: 0,
  emittedStates: [1, 2, 3],
  emitDelay: Duration(milliseconds: 100),
);
```

#### Snapshot Testing
```dart
await PureTestUtils.expectStateSnapshot(
  state,
  'test/snapshots/state.json',
  toJson: (s) => s.toJson(),
);
```

#### Widget Testing
```dart
testWidgets('counter test', (tester) async {
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
```

#### Golden Testing
```dart
await PureGoldenTest.testWithStore(
  tester: tester,
  store: store,
  widget: MyWidget(),
  goldenFile: 'goldens/my_widget.png',
);
```

---

### 9. **Batching & Replay** ⏯️

#### Action Batching
```dart
await store.batch(() {
  dispatch(Action1());
  dispatch(Action2());
  dispatch(Action3());
}); // Single state update
```

#### Time-Travel Debugging
```dart
store.enableReplay(maxHistory: 100);

// Navigate history
store.replayBack(steps: 5);
store.replay(toIndex: 10);
store.replayToWhere((state) => state.userId == 42);

// Advanced recording
final recorder = PureStateRecorder<MyState>();
final transitions = recorder.findByAction('IncrementAction');
```

---

### 10. **Performance Optimizations** ⚡

#### Improved Equality Checks
```dart
// Now includes hashCode pre-check for faster rejection
static bool eq(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.hashCode != b.hashCode) return false; // Quick rejection
  return a == b;
}
```

This micro-optimization can significantly improve performance for complex equality checks.

---

## 📝 Developer Experience

### VSCode Snippets
20+ code snippets for rapid development:
- `purestore` - Create a store
- `pureaction` - Create an action
- `pureasyncaction` - Create async action
- `pureauthorizedaction` - Create authorized action
- `pureretryableaction` - Create retryable action
- `purebuilder` - Create builder widget
- `pureselector` - Create selector
- `purecomputed2` - Create computed selector
- And many more...

### Enhanced Documentation
- Comprehensive `EXAMPLES.md` with all features
- Migration guides updated
- API documentation improved
- Best practices documented

---

## 📊 Pub.dev Optimization

### Enhanced Topics
Added 9 more relevant topics for better discoverability:
- `bloc`, `riverpod`, `provider`
- `flutter`, `dart`, `async`
- `testing`, `middleware`, `immutable`

### Example Improvements
- Richer example application
- Better code comments
- More use cases demonstrated

---

## 🎯 Breaking Changes

**None!** All improvements are backward compatible. Existing code continues to work without modifications.

---

## 📈 Metrics

### New Files Added: 9
1. `pure_async_value.dart` (297 lines)
2. `pure_store_family.dart` (209 lines)
3. `pure_auto_dispose_store.dart` (259 lines)
4. `pure_batch_extension.dart` (241 lines)
5. `pure_action_enhancements.dart` (339 lines)
6. `pure_computed_selector.dart` (421 lines)
7. `pure_flutter_test_utils.dart` (319 lines)
8. Enhanced `pure_test_utils.dart` (+208 lines)
9. VSCode snippets file

### Total New Code: ~2,300 lines
### Test Coverage: Comprehensive utilities added
### Dependencies: Still ZERO! 🎉

---

## 🚀 What's Next

### Recommended for v1.2.0:
1. **Code Generation**: `pure_state_generator` package
2. **DevTools Extension**: Browser-based debugging
3. **Effect System**: Reactive side effects
4. **Performance Profiler**: Built-in profiling API

### Community Building:
1. Discord/Slack server
2. YouTube tutorial series
3. Blog post series
4. Flutter conference talks

---

## 💡 Migration Guide

No migration needed! All new features are opt-in.

### To Start Using New Features:

```dart
import 'package:pure_state/pure_state.dart';

// Everything is now available!
```

See `EXAMPLES.md` for comprehensive usage examples.

---

## 🙏 Acknowledgments

This release brings Pure State to feature parity with major state management solutions while maintaining its core philosophy:

- **Zero Dependencies**
- **High Performance**
- **Developer Control**
- **Type Safety**

Pure State now offers:
- ✅ AsyncValue (like Riverpod)
- ✅ Family Pattern (like Riverpod)
- ✅ Auto-Dispose (like Riverpod)
- ✅ Authorization (unique to Pure State)
- ✅ Validation (unique to Pure State)
- ✅ Retry Logic (unique to Pure State)
- ✅ Computed Selectors (enhanced)
- ✅ Advanced Testing (like BLoC Test)
- ✅ Golden Testing (enhanced)
- ✅ Time-Travel Debugging (enhanced)

**Pure State is now production-ready for enterprise applications!** 🎉

---

## 📄 License

MIT License - Same as before

---

## 🔗 Links

- [GitHub](https://github.com/emrhnzngn/pure_state)
- [Pub.dev](https://pub.dev/packages/pure_state)
- [Examples](EXAMPLES.md)
- [Contributing](CONTRIBUTING.md)
- [Migration from BLoC](docs/migration-from-bloc.md)

---

**Version:** 1.1.0  
**Release Date:** January 2026  
**Status:** Production Ready ✅

