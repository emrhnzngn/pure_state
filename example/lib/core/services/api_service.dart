import '../../features/auth/models/user_model.dart';
import '../../features/tasks/models/task_model.dart';

/// Simulated API service for demo purposes.
class ApiService {
  // Simulate network delay
  static Future<void> _delay([Duration? duration]) async {
    await Future.delayed(duration ?? const Duration(seconds: 1));
  }

  /// Simulated login.
  static Future<User> login(String username, String password) async {
    await _delay();

    // Simulate different users
    if (username == 'admin') {
      return const User(
        id: 1,
        name: 'Admin User',
        email: 'admin@test.com',
        role: UserRole.admin,
      );
    } else if (username == 'user') {
      return const User(
        id: 2,
        name: 'Regular User',
        email: 'user@test.com',
        role: UserRole.user,
      );
    } else {
      throw Exception('Invalid credentials');
    }
  }

  /// Get user profile.
  static Future<User> getUserProfile(int userId) async {
    await _delay();

    if (userId == 1) {
      return const User(
        id: 1,
        name: 'Admin User',
        email: 'admin@test.com',
        role: UserRole.admin,
      );
    } else {
      return const User(
        id: 2,
        name: 'Regular User',
        email: 'user@test.com',
        role: UserRole.user,
      );
    }
  }

  /// Get tasks for a user.
  static Future<List<Task>> getTasks(int userId) async {
    await _delay();

    // Simulate different tasks for different users
    return [
      Task(
        id: '1',
        title: 'Welcome to Pure State!',
        description: 'This is your first task',
        completed: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        userId: userId,
      ),
      Task(
        id: '2',
        title: 'Explore AsyncValue',
        description: 'Check out how AsyncValue handles async states',
        completed: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        userId: userId,
      ),
      Task(
        id: '3',
        title: 'Try Authorization',
        description: 'Only admins can delete other users\' tasks',
        completed: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        completedAt: DateTime.now().subtract(const Duration(hours: 2)),
        userId: userId,
      ),
    ];
  }

  /// Create a new task.
  static Future<void> createTask(Task task) async {
    await _delay(const Duration(milliseconds: 500));
    // Simulate success
  }

  /// Delete a task.
  static Future<void> deleteTask(String taskId) async {
    await _delay(const Duration(milliseconds: 300));
    // Simulate success
  }

  /// Update a task.
  static Future<void> updateTask(Task task) async {
    await _delay(const Duration(milliseconds: 300));
    // Simulate success
  }
}

/// Custom exception for network errors.
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}
