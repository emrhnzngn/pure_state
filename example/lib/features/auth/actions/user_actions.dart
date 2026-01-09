import 'package:pure_state/pure_state.dart';
import '../../../core/services/api_service.dart';
import '../states/user_state.dart';
import '../../tasks/states/task_state.dart';

/// Login action with retry logic for network failures.
class LoginAction extends PureRetryableAction<UserState> {
  LoginAction(this.username, this.password);

  final String username;
  final String password;

  @override
  int get maxRetries => 3;

  @override
  Duration get retryDelay => const Duration(seconds: 2);

  @override
  bool shouldRetry(Object error) {
    // Only retry on network errors
    return error is NetworkException;
  }

  @override
  Future<UserState> execute(UserState currentState) async {
    // Önce loading state'i set et
    // Bu state store'a hemen uygulanacak ve UI loading gösterecek
    // Sonra executeWithRetry'yi çağıracağız
    final loadingState = currentState.copyWith(
      currentUser: const AsyncValue.loading(),
      isAuthenticated: false,
    );

    // Şimdi gerçek login işlemini yap
    try {
      return await super.execute(loadingState);
    } catch (e, stack) {
      return loadingState.copyWith(
        currentUser: AsyncError(e, stack),
        isAuthenticated: false,
      );
    }
  }

  @override
  Future<UserState> executeWithRetry(UserState state) async {
    try {
      final user = await ApiService.login(username, password);
      return state.copyWith(
        currentUser: AsyncData(user),
        isAuthenticated: true,
      );
    } catch (e, stack) {
      return state.copyWith(
        currentUser: AsyncError(e, stack),
        isAuthenticated: false,
      );
    }
  }
}

/// Logout action.
class LogoutAction extends PureAction<UserState> {
  LogoutAction({this.taskStore});

  final PureStore<TaskState>? taskStore;

  @override
  UserState execute(UserState currentState) {
    // Task state'i temizle
    taskStore?.setValue(const TaskState());

    return const UserState(
      currentUser: AsyncValue.data(null),
      isAuthenticated: false,
    );
  }
}

/// Load user profile action.
class LoadUserProfileAction extends PureRetryableAction<UserState> {
  LoadUserProfileAction(this.userId);

  final int userId;

  @override
  int get maxRetries => 2;

  @override
  Future<UserState> executeWithRetry(UserState state) async {
    try {
      final user = await ApiService.getUserProfile(userId);
      return state.copyWith(
        currentUser: AsyncData(user),
        isAuthenticated: true,
      );
    } catch (e, stack) {
      return state.copyWith(currentUser: AsyncError(e, stack));
    }
  }
}
