/// Todo model representing a single task item.
class Todo {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String category;
  final int priority; // 0: low, 1: medium, 2: high

  const Todo({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.category = 'Genel',
    this.priority = 1,
  });

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    String? category,
    int? priority,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      priority: priority ?? this.priority,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          isCompleted == other.isCompleted &&
          createdAt == other.createdAt &&
          completedAt == other.completedAt &&
          category == other.category &&
          priority == other.priority;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      (description?.hashCode ?? 0) ^
      isCompleted.hashCode ^
      createdAt.hashCode ^
      (completedAt?.hashCode ?? 0) ^
      category.hashCode ^
      priority.hashCode;

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, isCompleted: $isCompleted, category: $category, priority: $priority)';
  }
}

/// Todo state containing all todos and filter settings.
class TodoState {
  final List<Todo> todos;
  final String searchQuery;
  final String? selectedCategory;
  final TodoFilter filter;
  final bool isLoading;
  final String? error;

  const TodoState({
    this.todos = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.filter = TodoFilter.all,
    this.isLoading = false,
    this.error,
  });

  TodoState copyWith({
    List<Todo>? todos,
    String? searchQuery,
    String? selectedCategory,
    TodoFilter? filter,
    bool? isLoading,
    String? error,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Get filtered and searched todos
  List<Todo> get filteredTodos {
    // Create a mutable copy of the todos list
    var result = List<Todo>.from(todos);

    // Apply filter
    switch (filter) {
      case TodoFilter.all:
        break;
      case TodoFilter.active:
        result = result.where((todo) => !todo.isCompleted).toList();
        break;
      case TodoFilter.completed:
        result = result.where((todo) => todo.isCompleted).toList();
        break;
    }

    // Apply category filter
    if (selectedCategory != null) {
      result = result
          .where((todo) => todo.category == selectedCategory)
          .toList();
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((todo) {
        return todo.title.toLowerCase().contains(query) ||
            (todo.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort by priority (high first) and creation date
    result.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return result;
  }

  /// Get all unique categories
  List<String> get categories {
    final categoryList = todos.map((todo) => todo.category).toSet().toList();
    categoryList.sort();
    return categoryList;
  }

  /// Get statistics
  TodoStats get stats {
    final total = todos.length;
    final completed = todos.where((todo) => todo.isCompleted).length;
    final active = total - completed;
    final highPriority = todos
        .where((todo) => todo.priority == 2 && !todo.isCompleted)
        .length;

    return TodoStats(
      total: total,
      completed: completed,
      active: active,
      highPriority: highPriority,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoState &&
          runtimeType == other.runtimeType &&
          todos == other.todos &&
          searchQuery == other.searchQuery &&
          selectedCategory == other.selectedCategory &&
          filter == other.filter &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode =>
      todos.hashCode ^
      searchQuery.hashCode ^
      (selectedCategory?.hashCode ?? 0) ^
      filter.hashCode ^
      isLoading.hashCode ^
      (error?.hashCode ?? 0);
}

/// Filter options for todos
enum TodoFilter { all, active, completed }

/// Statistics about todos
class TodoStats {
  final int total;
  final int completed;
  final int active;
  final int highPriority;

  const TodoStats({
    required this.total,
    required this.completed,
    required this.active,
    required this.highPriority,
  });
}
