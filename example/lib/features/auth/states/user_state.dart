import 'package:pure_state/pure_state.dart';
import '../models/user_model.dart';

/// State for user authentication and profile.
class UserState {
  const UserState({
    this.currentUser = const AsyncValue.loading(),
    this.isAuthenticated = false,
  });

  final AsyncValue<User> currentUser;
  final bool isAuthenticated;

  UserState copyWith({
    AsyncValue<User>? currentUser,
    bool? isAuthenticated,
  }) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserState &&
          runtimeType == other.runtimeType &&
          currentUser == other.currentUser &&
          isAuthenticated == other.isAuthenticated;

  @override
  int get hashCode => Object.hash(currentUser, isAuthenticated);

  @override
  String toString() =>
      'UserState(isAuthenticated: $isAuthenticated, user: $currentUser)';
}

