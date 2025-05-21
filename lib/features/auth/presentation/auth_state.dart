part of 'auth_cubit.dart'; // We'll create auth_cubit.dart next


abstract class AuthState extends Equatable {
  final List<String> defaultAvatarUrls;
  final bool isLoadingAvatars;
  final String? avatarFetchError;

  const AuthState({
    List<String>? defaultAvatarUrls,
    bool? isLoadingAvatars,
    this.avatarFetchError,
  })  : defaultAvatarUrls = defaultAvatarUrls ?? const [],
        isLoadingAvatars = isLoadingAvatars ?? false;

  @override
  List<Object?> get props => [defaultAvatarUrls, isLoadingAvatars, avatarFetchError];
}

class AuthInitial extends AuthState {
  AuthInitial() : super();
}

class AuthLoading extends AuthState {
  AuthLoading() : super();
}

// State when the user is successfully authenticated with the backend
class Authenticated extends AuthState {
  final String token; // The JWT token from the backend
  final User user;    // User details (should align with backend's UserRead/UserPublic)
                       // Ensure User model has fields like anonymousId, username, etc.
  const Authenticated({
    required this.token,
    required this.user,
    super.defaultAvatarUrls,
    super.isLoadingAvatars,
    super.avatarFetchError,
  });

  @override
  List<Object?> get props => super.props..addAll([token, user]);
}

// State when the user is not authenticated (e.g., no token, logged out)
// The UI would typically show options to "sign in" or "register" (anonymously in our case).
class Unauthenticated extends AuthState {
  // Optionally, could hold a reason for unauthentication if needed
  // e.g., SessionExpired, UserLoggedOut
  const Unauthenticated({
    super.defaultAvatarUrls,
    super.isLoadingAvatars,
    super.avatarFetchError,
  });
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(
    this.message, {
    super.defaultAvatarUrls,
    super.isLoadingAvatars,
    super.avatarFetchError,
  });

  @override
  List<Object?> get props => super.props..add(message);
}

// State when account deletion is in progress
class AuthDeletionInProgress extends AuthState {
  final String token; // The token of the user whose account is being deleted
  final User user;    // The user details
  const AuthDeletionInProgress({
    required this.token,
    required this.user,
    super.defaultAvatarUrls,
    super.isLoadingAvatars,
    super.avatarFetchError,
  });

  @override
  List<Object?> get props => super.props..addAll([token, user]);
}

// State when account deletion has failed
class AuthDeletionFailure extends AuthState {
  final String message;
  final String token; // The token of the user whose account deletion failed
  final User user;    // The user details (to potentially revert to Authenticated state)
  const AuthDeletionFailure(
    this.message, {
    required this.token,
    required this.user,
    super.defaultAvatarUrls,
    super.isLoadingAvatars,
    super.avatarFetchError,
  });

  @override
  List<Object?> get props => super.props..addAll([message, token, user]);
}
