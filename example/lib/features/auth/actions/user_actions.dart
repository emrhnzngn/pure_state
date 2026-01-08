import 'package:pure_state/pure_state.dart';
import '../../../core/services/api_service.dart';
import '../states/user_state.dart';

/// Login action with retry logic for network failures.
class LoginAction extends PureRetryableAction<UserState> {
  LoginAction(this.email, this.password);

  final String email;
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
  Future<UserState> executeWithRetry(UserState state) async {
    try {
      final user = await ApiService.login(email, password);
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
  @override
  UserState execute(UserState currentState) {
    return const UserState(
      currentUser: AsyncValue.loading(),
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
