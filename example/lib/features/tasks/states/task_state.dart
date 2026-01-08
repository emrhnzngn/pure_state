import 'package:pure_state/pure_state.dart';
import '../models/task_model.dart';

/// State for task management.
class TaskState {
  const TaskState({
    this.tasks = const AsyncValue.loading(),
    this.filter = TaskFilter.all,
  });

  final AsyncValue<List<Task>> tasks;
  final TaskFilter filter;

  /// Filtered tasks based on current filter.
  List<Task> get filteredTasks {
    return tasks.dataOrNull?.where((task) {
          switch (filter) {
            case TaskFilter.all:
              return true;
            case TaskFilter.active:
              return !task.completed;
            case TaskFilter.completed:
              return task.completed;
          }
        }).toList() ??
        [];
  }

  /// Task statistics.
  int get totalTasks => tasks.dataOrNull?.length ?? 0;
  int get completedTasks =>
      tasks.dataOrNull?.where((t) => t.completed).length ?? 0;
  int get activeTasks =>
      tasks.dataOrNull?.where((t) => !t.completed).length ?? 0;
  double get completionRate =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  TaskState copyWith({
    AsyncValue<List<Task>>? tasks,
    TaskFilter? filter,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskState &&
          runtimeType == other.runtimeType &&
          tasks == other.tasks &&
          filter == other.filter;

  @override
  int get hashCode => Object.hash(tasks, filter);

  @override
  String toString() => 'TaskState(tasks: $tasks, filter: $filter)';
}

/// Task filter options.
enum TaskFilter {
  all,
  active,
  completed;

  String get displayName {
    switch (this) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.active:
        return 'Active';
      case TaskFilter.completed:
        return 'Completed';
    }
  }
}

