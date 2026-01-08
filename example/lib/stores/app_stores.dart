import 'package:pure_state/pure_state.dart';
import '../models/todo_model.dart';
import '../models/app_settings_model.dart';

/// Creates and configures all app stores
class AppStores {
  late final StoreContainer container;
  late final PureStore<TodoState> todoStore;
  late final PureStore<AppSettingsState> settingsStore;

  AppStores() {
    container = StoreContainer();

    todoStore = PureStore<TodoState>(
      const TodoState(),
      container: container,
      batchDelay: const Duration(milliseconds: 16),
      useAdaptiveBatchDelay: true,
    );

    settingsStore = PureStore<AppSettingsState>(
      const AppSettingsState(),
      container: container,
    );

    container.register<TodoState>(todoStore);
    container.register<AppSettingsState>(settingsStore);
  }

  /// Dispose all stores
  void dispose() {
    todoStore.dispose();
    settingsStore.dispose();
  }
}
