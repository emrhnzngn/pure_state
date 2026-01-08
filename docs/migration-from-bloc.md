# Migration Guide: BLoC to Pure State

This guide will help you migrate your Flutter application from BLoC to Pure State.

## Table of Contents
- [Key Differences](#key-differences)
- [Migration Steps](#migration-steps)
- [Code Comparison](#code-comparison)
- [Common Patterns](#common-patterns)
- [Gotchas](#gotchas)

## Key Differences

| Aspect | BLoC | Pure State |
|--------|------|------------|
| Core Concept | Events → BLoC → States | Actions → Store → State |
| State Container | `Bloc<Event, State>` | `PureStore<State>` |
| State Updates | `emit(newState)` | `return newState` |
| Side Effects | `on<Event>()` handlers | `onResult()` in actions |
| Middleware | `Transformers` | `Middleware` system |
| Testing | `blocTest` package | `PureTestUtils` |

## Migration Steps

### Step 1: Update Dependencies

**Before (BLoC):**
```yaml
dependencies:
  flutter_bloc: ^8.0.0
  bloc: ^8.0.0
```

**After (Pure State):**
```yaml
dependencies:
  pure_state: ^1.0.0
```

### Step 2: Convert Events to Actions

**Before (BLoC):**
```dart
abstract class CounterEvent {}

class IncrementEvent extends CounterEvent {}

class DecrementEvent extends CounterEvent {}
```

**After (Pure State):**
```dart
class IncrementAction extends PureAction<CounterState> {
  @override
  CounterState execute(CounterState state) {
    return state.copyWith(count: state.count + 1);
  }
}

class DecrementAction extends PureAction<CounterState> {
  @override
  CounterState execute(CounterState state) {
    return state.copyWith(count: state.count - 1);
  }
}
```

### Step 3: Convert Bloc to Store

**Before (BLoC):**
```dart
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(count: 0)) {
    on<IncrementEvent>((event, emit) {
      emit(state.copyWith(count: state.count + 1));
    });
    
    on<DecrementEvent>((event, emit) {
      emit(state.copyWith(count: state.count - 1));
    });
  }
}
```

**After (Pure State):**
```dart
final counterStore = PureStore<CounterState>(
  CounterState(count: 0),
);

// Actions handle their own logic
```

### Step 4: Update Providers

**Before (BLoC):**
```dart
BlocProvider(
  create: (context) => CounterBloc(),
  child: MyApp(),
)
```

**After (Pure State):**
```dart
PureProvider(
  store: counterStore,
  child: MyApp(),
)
```

### Step 5: Update Widgets

**Before (BLoC):**
```dart
BlocBuilder<CounterBloc, CounterState>(
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)
```

**After (Pure State):**
```dart
PureBuilder<CounterState>(
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)
```

### Step 6: Update Event Dispatching

**Before (BLoC):**
```dart
context.read<CounterBloc>().add(IncrementEvent());
```

**After (Pure State):**
```dart
PureProvider.of<CounterState>(context).dispatch(IncrementAction());
// Or store directly
counterStore.dispatch(IncrementAction());
```

## Code Comparison

### Complete Example

#### BLoC Version
```dart
// Events
abstract class TodoEvent {}
class LoadTodosEvent extends TodoEvent {}
class AddTodoEvent extends TodoEvent {
  final Todo todo;
  AddTodoEvent(this.todo);
}

// Bloc
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository repository;
  
  TodoBloc(this.repository) : super(TodoState.initial()) {
    on<LoadTodosEvent>(_onLoadTodos);
    on<AddTodoEvent>(_onAddTodo);
  }
  
  Future<void> _onLoadTodos(LoadTodosEvent event, Emitter<TodoState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final todos = await repository.loadTodos();
      emit(state.copyWith(todos: todos, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }
  
  Future<void> _onAddTodo(AddTodoEvent event, Emitter<TodoState> emit) async {
    final newTodos = [...state.todos, event.todo];
    emit(state.copyWith(todos: newTodos));
  }
}

// Widget
BlocProvider(
  create: (context) => TodoBloc(repository),
  child: BlocBuilder<TodoBloc, TodoState>(
    builder: (context, state) {
      if (state.isLoading) return CircularProgressIndicator();
      return ListView(
        children: state.todos.map((todo) => TodoItem(todo)).toList(),
      );
    },
  ),
)
```

#### Pure State Version
```dart
// Actions
class LoadTodosAction extends PureAction<TodoState> {
  final TodoRepository repository;
  LoadTodosAction(this.repository);
  
  @override
  Future<TodoState> execute(TodoState state) async {
    try {
      final todos = await repository.loadTodos();
      return state.copyWith(todos: todos, isLoading: false);
    } catch (e) {
      return state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

class AddTodoAction extends PureAction<TodoState> {
  final Todo todo;
  AddTodoAction(this.todo);
  
  @override
  TodoState execute(TodoState state) {
    return state.copyWith(todos: [...state.todos, todo]);
  }
}

// Store
final todoStore = PureStore<TodoState>(TodoState.initial());

// Widget
PureProvider(
  store: todoStore,
  child: PureBuilder<TodoState>(
    builder: (context, state) {
      if (state.isLoading) return CircularProgressIndicator();
      return ListView(
        children: state.todos.map((todo) => TodoItem(todo)).toList(),
      );
    },
  ),
)
```

## Common Patterns

### 1. Transformers → Debounce/Throttle

**BLoC:**
```dart
on<SearchEvent>(
  _onSearch,
  transformer: debounce(Duration(milliseconds: 300)),
);
```

**Pure State:**
```dart
class SearchAction extends PureAction<SearchState> {
  @override
  Duration get debounceDuration => Duration(milliseconds: 300);
  
  @override
  Future<SearchState> execute(SearchState state) async {
    // Search logic
  }
}
```

### 2. BlocListener → PureListener

**BLoC:**
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthSuccess) {
      Navigator.pushReplacement(context, HomePage());
    }
  },
  child: LoginForm(),
)
```

**Pure State:**
```dart
PureListener<AuthState>(
  listenWhen: (prev, curr) => curr.isAuthenticated,
  listener: (context, state) {
    Navigator.pushReplacement(context, HomePage());
  },
  child: LoginForm(),
)
```

### 3. Multiple Blocs → Multiple Stores

**BLoC:**
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => UserBloc()),
    BlocProvider(create: (context) => SettingsBloc()),
  ],
  child: MyApp(),
)
```

**Pure State:**
```dart
PureMultiProvider(
  providers: [
    (child) => PureProvider(store: userStore, child: child),
    (child) => PureProvider(store: settingsStore, child: child),
  ],
  child: MyApp(),
)
```

### 4. Selective Rebuilds

**BLoC:**
```dart
BlocSelector<UserBloc, UserState, String>(
  selector: (state) => state.name,
  builder: (context, name) => Text(name),
)
```

**Pure State:**
```dart
PureSelector<UserState, String>(
  selector: (state) => state.name,
  builder: (context, name) => Text(name),
)
```

## Gotchas

### 1. Error Handling

**BLoC** uses `emit()` in try-catch blocks.  
**Pure State** returns error states or uses `errorStream`.

```dart
// BLoC
try {
  emit(SuccessState(data));
} catch (e) {
  emit(ErrorState(e));
}

// Pure State
try {
  return state.copyWith(data: data);
} catch (e) {
  return state.copyWith(error: e.toString());
}
```

### 2. Store Disposal

**BLoC** auto-closes with BlocProvider.  
**Pure State** requires manual disposal if not using PureProvider.

```dart
// Pure State
@override
void dispose() {
  store.dispose();  // Only if created locally
  super.dispose();
}
```

### 3. Testing

**BLoC:**
```dart
blocTest<CounterBloc, CounterState>(
  'emits [1] when IncrementEvent is added',
  build: () => CounterBloc(),
  act: (bloc) => bloc.add(IncrementEvent()),
  expect: () => [CounterState(count: 1)],
);
```

**Pure State:**
```dart
test('increments count when IncrementAction dispatched', () async {
  final store = PureStore(CounterState(count: 0));
  
  await PureTestUtils.waitForAction(
    store,
    IncrementAction(),
    expectedState: CounterState(count: 1),
  );
  
  expect(store.state.count, 1);
});
```

## Benefits of Migration

✅ **Less boilerplate** - No need for separate event classes  
✅ **Better performance** - Sampling equality, priority queue  
✅ **Simpler testing** - Direct action execution  
✅ **Type safety** - Actions know their state type  
✅ **Built-in tools** - Debugger, persistence out of the box  

## Need Help?

- Check the [Pure State documentation](../README.md)
- Look at the [example app](../example/)
- Open an [issue](https://github.com/emrhnzngn/pure_state/issues) if you're stuck

