part of 'auth_cubit.dart'; // We'll create auth_cubit.dart next


abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

// For MVP, anonymous ID is auto-generated.
// This state means we have an anonymous ID.
class AuthSuccess extends AuthState {
  final User user; // Now holds a User object

  const AuthSuccess(this.user);

  @override
  List<Object?> get props => [user]; // User model should handle Equatable correctly
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}


class AuthRequiresUsername extends AuthState{
  final String anonymousId;

  const AuthRequiresUsername(this.anonymousId);

  @override
  List<Object?> get props => [anonymousId];
}
