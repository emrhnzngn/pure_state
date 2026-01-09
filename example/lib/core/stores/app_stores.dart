import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';
import '../../features/auth/states/user_state.dart';
import '../../features/tasks/states/task_state.dart';
import '../../features/settings/states/settings_state.dart';

/// Global container for all stores with dependency injection.
class AppStores {
  AppStores() {
    // Initialize stores first (they need container)
    // Note: userStore and taskStore are late final, so they're initialized here
    // Register stores in container for cross-store dependencies
    container.register<UserState>(userStore);
    container.register<TaskState>(taskStore);
    container.register<SettingsState>(settingsStore);

    // Enable history for time-travel debugging
    userStore.enableReplay(maxHistory: 50);
    taskStore.enableReplay(maxHistory: 100);

    // Add validation middleware to settings
    settingsStore.addMiddlewareWithResult(
      validationMiddleware<SettingsState>(
        onValidationError: (errors) {
          debugPrint('⚠️ Validation errors: ${errors.join(", ")}');
        },
      ),
    );
  }

  /// Store container for dependency injection.
  final container = StoreContainer();

  /// User authentication store.
  late final userStore = PureStore<UserState>(
    const UserState(),
    container: container,
  );

  /// Task management store (will be created per user with Family).
  late final taskStore = PureStore<TaskState>(
    const TaskState(),
    container: container,
  );

  /// Settings store with persistence.
  final settingsStore = PureStore<SettingsState>(const SettingsState());

  /// Family for per-user task stores with auto-dispose.
  late final taskStoreFamily = PureStoreFamily<TaskState, int>(
    (userId) => PureAutoDisposeStore<TaskState>(
      const TaskState(),
      keepAliveFor: const Duration(minutes: 5),
      onAutoDispose: () =>
          debugPrint('🗑️ Task store for user $userId disposed'),
      container: container,
    ),
  );

  /// Dispose all stores.
  void dispose() {
    userStore.dispose();
    taskStore.dispose();
    settingsStore.dispose();
    taskStoreFamily.disposeAll();
  }
}

/// Global app stores instance.
final appStores = AppStores();
