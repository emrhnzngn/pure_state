import 'dart:async';
import 'package:pure_state/pure_state.dart';
import '../models/todo_model.dart';

/// Action to add a new todo
class AddTodoAction extends PureAction<TodoState> {
  final String title;
  final String? description;
  final String category;
  final int todoPriority;

  AddTodoAction({
    required this.title,
    this.description,
    this.category = 'Genel',
    this.todoPriority = 1,
  });

  @override
  FutureOr<TodoState> execute(TodoState currentState) async {
    // Simulate async operation (e.g., API call)
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      category: category,
      priority: todoPriority,
      createdAt: DateTime.now(),
    );

    return currentState.copyWith(todos: [...currentState.todos, newTodo]);
  }
}

/// Action to toggle todo completion status
class ToggleTodoAction extends PureAction<TodoState> {
  final String todoId;

  ToggleTodoAction(this.todoId);

  @override
  FutureOr<TodoState> execute(TodoState currentState) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final updatedTodos = currentState.todos.map((todo) {
      if (todo.id == todoId) {
        return todo.copyWith(
          isCompleted: !todo.isCompleted,
          completedAt: !todo.isCompleted ? DateTime.now() : null,
        );
      }
      return todo;
    }).toList();

    return currentState.copyWith(todos: updatedTodos);
  }
}

/// Action to delete a todo
class DeleteTodoAction extends PureAction<TodoState> {
  final String todoId;

  DeleteTodoAction(this.todoId);

  @override
  FutureOr<TodoState> execute(TodoState currentState) {
    final updatedTodos = currentState.todos
        .where((todo) => todo.id != todoId)
        .toList();

    return currentState.copyWith(todos: updatedTodos);
  }
}

/// Action to update todo
class UpdateTodoAction extends PureAction<TodoState> {
  final String todoId;
  final String? title;
  final String? description;
  final String? category;
  final int? todoPriority;

  UpdateTodoAction({
    required this.todoId,
    this.title,
    this.description,
    this.category,
    this.todoPriority,
  });

  @override
  FutureOr<TodoState> execute(TodoState currentState) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final updatedTodos = currentState.todos.map((todo) {
      if (todo.id == todoId) {
        return todo.copyWith(
          title: title ?? todo.title,
          description: description ?? todo.description,
          category: category ?? todo.category,
          priority: todoPriority ?? todo.priority,
        );
      }
      return todo;
    }).toList();

    return currentState.copyWith(todos: updatedTodos);
  }
}

/// Action to set search query
class SetSearchQueryAction extends PureAction<TodoState> {
  final String query;

  SetSearchQueryAction(this.query);

  @override
  FutureOr<TodoState> execute(TodoState currentState) {
    return currentState.copyWith(searchQuery: query);
  }
}

/// Action to set selected category filter
class SetCategoryFilterAction extends PureAction<TodoState> {
  final String? category;

  SetCategoryFilterAction(this.category);

  @override
  FutureOr<TodoState> execute(TodoState currentState) {
    return currentState.copyWith(selectedCategory: category);
  }
}

/// Action to set todo filter (all/active/completed)
class SetTodoFilterAction extends PureAction<TodoState> {
  final TodoFilter filter;

  SetTodoFilterAction(this.filter);

  @override
  FutureOr<TodoState> execute(TodoState currentState) {
    // Only change the filter, keep category filter independent
    return currentState.copyWith(filter: filter);
  }
}

/// Action to set loading state
class SetLoadingAction extends PureAction<TodoState> {
  final bool isLoading;

  SetLoadingAction(this.isLoading);

  @override
  FutureOr<TodoState> execute(TodoState currentState) {
    return currentState.copyWith(isLoading: isLoading);
  }
}

/// Action to load todos (simulated async operation)
class LoadTodosAction extends PureAction<TodoState> {
  @override
  Duration? get timeout => const Duration(seconds: 5);

  @override
  FutureOr<TodoState> execute(TodoState currentState) async {
    // Loading state should already be set by SetLoadingAction (via executeBatch)
    // Just ensure error is cleared
    final loadingState = currentState.copyWith(error: null);

    try {
      // Simulate loaded todos
      final loadedTodos = [
        Todo(
          id: '1',
          title: 'Pure State paketini öğren',
          description: 'Dokümantasyonu oku ve örnekleri incele',
          category: 'Öğrenme',
          priority: 2,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          isCompleted: true,
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Todo(
          id: '2',
          title: 'Örnek uygulama geliştir',
          description: 'Kapsamlı bir örnek uygulama oluştur',
          category: 'Geliştirme',
          priority: 2,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Todo(
          id: '3',
          title: 'Test yaz',
          description: 'Unit testler ve widget testleri ekle',
          category: 'Test',
          priority: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Todo(
          id: '4',
          title: 'Dokümantasyon güncelle',
          description: 'README ve API dokümantasyonunu güncelle',
          category: 'Dokümantasyon',
          priority: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      return loadingState.copyWith(todos: loadedTodos, isLoading: false);
    } catch (e) {
      return loadingState.copyWith(
        isLoading: false,
        error: 'Todos yüklenirken hata oluştu: $e',
      );
    }
  }
}

/// Action to clear completed todos
class ClearCompletedAction extends PureAction<TodoState> {
  @override
  FutureOr<TodoState> execute(TodoState currentState) {
    final activeTodos = currentState.todos
        .where((todo) => !todo.isCompleted)
        .toList();

    return currentState.copyWith(todos: activeTodos);
  }
}

/// Action to delete all todos
class DeleteAllTodosAction extends PureAction<TodoState> {
  @override
  FutureOr<TodoState> execute(TodoState currentState) {
    return currentState.copyWith(todos: []);
  }
}
