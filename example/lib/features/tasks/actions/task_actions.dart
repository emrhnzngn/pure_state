import 'package:pure_state/pure_state.dart';
import '../models/task_model.dart';
import '../../../core/services/api_service.dart';
import '../states/task_state.dart';

/// Load tasks action with retry logic.
class LoadTasksAction extends PureRetryableAction<TaskState> {
  LoadTasksAction(this.userId);

  final int userId;

  @override
  int get maxRetries => 3;

  @override
  Duration get retryDelay => const Duration(seconds: 1);

  @override
  bool shouldRetry(Object error) => error is NetworkException;

  @override
  Future<TaskState> executeWithRetry(TaskState state) async {
    try {
      final tasks = await ApiService.getTasks(userId);
      return state.copyWith(tasks: AsyncData(tasks));
    } catch (e, stack) {
      return state.copyWith(tasks: AsyncError(e, stack));
    }
  }
}

/// Create task action with authorization.
class CreateTaskAction extends PureAuthorizedAction<TaskState> {
  CreateTaskAction({required this.title, required this.description});

  final String title;
  final String description;

  @override
  bool authorize(TaskState state) {
    // Authorization logic would check user permissions
    // For this example, we'll assume authorized
    // In production, use container to access UserState
    return true;
  }

  @override
  Future<TaskState> executeAuthorized(TaskState state) async {
    // In production, get userId from UserState via container
    const userId = 1; // Placeholder

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      completed: false,
      createdAt: DateTime.now(),
      userId: userId,
    );

    try {
      await ApiService.createTask(newTask);

      final currentTasks = state.tasks.dataOrNull ?? [];
      return state.copyWith(tasks: AsyncData([...currentTasks, newTask]));
    } catch (e, stack) {
      return state.copyWith(tasks: AsyncError(e, stack));
    }
  }

  @override
  TaskState onUnauthorized(TaskState state) {
    // Could show a snackbar here
    return state;
  }
}

/// Delete task action with authorization.
class DeleteTaskAction extends PureAuthorizedAction<TaskState> {
  DeleteTaskAction(this.taskId);

  final String taskId;

  @override
  bool authorize(TaskState state) {
    // Authorization logic would check if user can delete this task
    // For this example, we'll assume authorized
    // In production, use container to access UserState
    return true;
  }

  @override
  Future<TaskState> executeAuthorized(TaskState state) async {
    try {
      await ApiService.deleteTask(taskId);

      final currentTasks = state.tasks.dataOrNull ?? [];
      return state.copyWith(
        tasks: AsyncData(currentTasks.where((t) => t.id != taskId).toList()),
      );
    } catch (e, stack) {
      return state.copyWith(tasks: AsyncError(e, stack));
    }
  }
}

/// Toggle task completion.
class ToggleTaskAction extends PureAction<TaskState> {
  ToggleTaskAction(this.taskId);

  final String taskId;

  @override
  Future<TaskState> execute(TaskState currentState) async {
    final tasks = currentState.tasks.dataOrNull ?? [];
    final updatedTasks = tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          completed: !task.completed,
          completedAt: !task.completed ? DateTime.now() : null,
        );
      }
      return task;
    }).toList();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));
      return currentState.copyWith(tasks: AsyncData(updatedTasks));
    } catch (e, stack) {
      return currentState.copyWith(tasks: AsyncError(e, stack));
    }
  }
}

/// Set task filter.
class SetFilterAction extends PureAction<TaskState> {
  SetFilterAction(this.filter);

  final TaskFilter filter;

  @override
  TaskState execute(TaskState currentState) {
    return currentState.copyWith(filter: filter);
  }
}
