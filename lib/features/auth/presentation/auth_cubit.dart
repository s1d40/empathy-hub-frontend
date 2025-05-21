import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:empathy_hub_app/features/auth/presentation/models/user_model.dart'; // Import the User model
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import flutter_secure_storage
import 'package:empathy_hub_app/core/services/auth_api_service.dart'; // Import ApiService

part 'auth_state.dart'; // Links to the state file

class AuthCubit extends Cubit<AuthState> {
  final AuthApiService _apiService;
  // TODO: For production, use flutter_secure_storage for JWTs instead of SharedPreferences.
  static const String _authTokenKey = 'auth_token'; // Key for secure storage
  static const String _anonymousIdKey = 'anonymous_id'; // Key for SharedPreferences

  AuthCubit(this._apiService) : super(AuthInitial()) {
    checkAuthenticationStatus(); // Check status when cubit is created
  }

  Future<void> checkAuthenticationStatus() async {
    try {
      emit(AuthLoading());
      const secureStorage = FlutterSecureStorage();
      final prefs = await SharedPreferences.getInstance();
      final String? token = await secureStorage.read(key: _authTokenKey);
      final String? anonymousId = prefs.getString(_anonymousIdKey);

      if (token != null && token.isNotEmpty) {
        // Token exists, try to fetch user profile to validate it
        final userProfileMap = await _apiService.getUserProfile(token);
        if (userProfileMap != null) {
          final user = User.fromJson(userProfileMap); // Ensure User.fromJson exists
          // Ensure anonymousId is also stored if it wasn't or if it changed (unlikely for same user)
          if (prefs.getString(_anonymousIdKey) != user.anonymousId) {
            await prefs.setString(_anonymousIdKey, user.anonymousId);
          }
          emit(Authenticated(token: token, user: user));
        } else {
          // Token might be invalid or expired.
          // If we have an anonymousId, try to get a new token.
          if (anonymousId != null && anonymousId.isNotEmpty) {
            final newToken = await _apiService.getTokenByAnonymousId(anonymousId);
            if (newToken != null && newToken.isNotEmpty) {
              await secureStorage.write(key: _authTokenKey, value: newToken);
              final newUserProfileMap = await _apiService.getUserProfile(newToken);
              if (newUserProfileMap != null) {
                final user = User.fromJson(newUserProfileMap);
                // anonymousId should match, but good to be sure user object is from new profile
                await prefs.setString(_anonymousIdKey, user.anonymousId); 
                emit(Authenticated(token: newToken, user: user));
                return; // Successfully re-authenticated
              }
            }
          }
          // If re-authentication failed or no anonymousId, clear everything.
          await _clearAuthData(prefs);
          emit(Unauthenticated());
        }
      } else if (anonymousId != null && anonymousId.isNotEmpty) {
        // No token, but we have an anonymousId. Try to get a token.
        final newToken = await _apiService.getTokenByAnonymousId(anonymousId);
        if (newToken != null && newToken.isNotEmpty) {
          await secureStorage.write(key: _authTokenKey, value: newToken);
          final userProfileMap = await _apiService.getUserProfile(newToken);
          if (userProfileMap != null) {
            final user = User.fromJson(userProfileMap);
            await prefs.setString(_anonymousIdKey, user.anonymousId); // Store anonymousId from fresh profile
            emit(Authenticated(token: newToken, user: user));
            return; // Successfully authenticated
          }
        }
        // If getting token by anonymousId failed, clear anonymousId.
        await _clearAuthData(prefs);
        emit(Unauthenticated());
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthFailure("Authentication check failed: ${e.toString()}"));
      // Ensure we are in an Unauthenticated state on critical failure
      final prefs = await SharedPreferences.getInstance();
      await _clearAuthData(prefs);
      emit(Unauthenticated());
    }
  }

  Future<void> signInAnonymously({String? preferredUsername, String? avatarUrl}) async {
    // Capture current avatar state if we need to restore it on failure
    final List<String> currentDefaultAvatarUrls = state.defaultAvatarUrls;
    final String? currentAvatarFetchError = state.avatarFetchError;
    // isLoadingAvatars should be false if we are initiating a sign-in
    const bool currentIsLoadingAvatars = false; 

    try {
      emit(AuthLoading());
      const secureStorage = FlutterSecureStorage();
      final String? token = await _apiService.createAnonymousUser(
        username: preferredUsername,
        avatarUrl: avatarUrl, // Pass the selected avatar URL
      );
      
      if (token != null && token.isNotEmpty) {
        await secureStorage.write(key: _authTokenKey, value: token);
        final prefs = await SharedPreferences.getInstance(); // For anonymousId
        
        // After getting token, fetch user profile
        final userProfileMap = await _apiService.getUserProfile(token);
        if (userProfileMap != null) {
          final user = User.fromJson(userProfileMap);
          await prefs.setString(_anonymousIdKey, user.anonymousId); // Store anonymousId
          emit(Authenticated(token: token, user: user));
        } else {
          // This case is less likely if createAnonymousUser succeeded and returned a valid token
          // but handle it for robustness (e.g. immediate network issue after token retrieval)
          await secureStorage.delete(key: _authTokenKey);
          emit(AuthFailure(
            "Failed to fetch profile after sign-in.",
            defaultAvatarUrls: currentDefaultAvatarUrls,
            isLoadingAvatars: currentIsLoadingAvatars,
            avatarFetchError: currentAvatarFetchError,
          ));
          emit(Unauthenticated(
            defaultAvatarUrls: currentDefaultAvatarUrls,
            isLoadingAvatars: currentIsLoadingAvatars,
            avatarFetchError: currentAvatarFetchError,
          ));
        }
      } else {
        emit(AuthFailure(
          "Failed to sign in: No token received.",
          defaultAvatarUrls: currentDefaultAvatarUrls,
          isLoadingAvatars: currentIsLoadingAvatars,
          avatarFetchError: currentAvatarFetchError,
        ));
        emit(Unauthenticated(
          defaultAvatarUrls: currentDefaultAvatarUrls,
          isLoadingAvatars: currentIsLoadingAvatars,
          avatarFetchError: currentAvatarFetchError,
        ));
      }
    } catch (e) {
      emit(AuthFailure(
        "Sign-in error: ${e.toString()}",
        defaultAvatarUrls: currentDefaultAvatarUrls,
        isLoadingAvatars: currentIsLoadingAvatars,
        avatarFetchError: currentAvatarFetchError,
      ));
      emit(Unauthenticated(
        defaultAvatarUrls: currentDefaultAvatarUrls,
        isLoadingAvatars: currentIsLoadingAvatars,
        avatarFetchError: currentAvatarFetchError,
      ));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      // No need to instantiate secureStorage here if _clearAuthData handles it
      final prefs = await SharedPreferences.getInstance();
      await _clearAuthData(prefs); // _clearAuthData will handle secure storage for token
      // TODO: If backend implements a token invalidation or user logout endpoint, call it here.
      emit(Unauthenticated());
    } catch (e) {
      // Even if clearing storage fails, treat as unauthenticated.
      emit(AuthFailure("Sign-out error: ${e.toString()}"));
      // Attempt to clear prefs again in catch, though it might also fail
      try {
        final prefs = await SharedPreferences.getInstance();
        await _clearAuthData(prefs);
      } catch (_) {}
      emit(Unauthenticated());
    }
  }

  Future<void> _clearAuthData(SharedPreferences prefs) async {
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: _authTokenKey);
    await prefs.remove(_anonymousIdKey);
  }

  Future<void> fetchDefaultAvatars() async {
    // This method is primarily intended to be called when the state is Unauthenticated,
    // for example, on the UsernameSelectionPage, or from AppDrawer.
    // It should now work for Authenticated state as well.

    List<String> existingAvatars = state.defaultAvatarUrls;
    String? existingError = state.avatarFetchError; // Preserve previous error unless cleared
    bool isLoadingAvatarsNow = true; // Assume we are starting to load

    // Emit a loading state specific to current state type, preserving other state details
    if (state is Authenticated) {
      final s = state as Authenticated;
      emit(Authenticated(token: s.token, user: s.user, isLoadingAvatars: isLoadingAvatarsNow, defaultAvatarUrls: existingAvatars, avatarFetchError: null /* Clear previous error */));
    } else if (state is Unauthenticated) {
      final s = state as Unauthenticated;
      emit(Unauthenticated(
        isLoadingAvatars: isLoadingAvatarsNow,
        defaultAvatarUrls: s.defaultAvatarUrls, // Preserve existing list while loading
        avatarFetchError: null, // Clear previous error on new fetch attempt
      ));
    } else {
      // For other states like AuthLoading, AuthInitial, AuthFailure, etc.,
      // we might not want to trigger an avatar fetch or it might complicate state management.
      // For now, only allow fetching from Unauthenticated or Authenticated states.
      print("fetchDefaultAvatars called from state ${state.runtimeType}. Avatars not fetched if not Authenticated or Unauthenticated.");
      return;
    }

    try {
      final List<String> avatarUrls = await _apiService.getDefaultAvatarUrls();
      // Check current state again, as it might have changed during the async call
      if (state is Authenticated) {
        final s = state as Authenticated;
        emit(Authenticated(token: s.token, user: s.user, defaultAvatarUrls: avatarUrls, isLoadingAvatars: false, avatarFetchError: null));
      } else if (state is Unauthenticated) {
        emit(Unauthenticated(
          defaultAvatarUrls: avatarUrls,
          isLoadingAvatars: false,
          avatarFetchError: null,
        ));
      }
    } catch (e) {
      final errorMsg = "Failed to fetch avatars: ${e.toString()}";
      if (state is Authenticated) { // Check current state again
        final s = state as Authenticated;
        emit(Authenticated(token: s.token, user: s.user, defaultAvatarUrls: existingAvatars, isLoadingAvatars: false, avatarFetchError: errorMsg));
      } else if (state is Unauthenticated) { // Check current state again
        emit(Unauthenticated(
          defaultAvatarUrls: existingAvatars, // Keep old list on error
          isLoadingAvatars: false,
          avatarFetchError: errorMsg,
        ));
      }
    }
  }

  Future<void> updateUserProfile({
    // Optional parameters for fields that can be updated
    String? username,
    String? bio,
    String? pronouns,
    String? chatAvailability,
    String? avatarUrl,
    bool? isActive,
  }) async {
    if (state is Authenticated) {
      final authenticatedState = state as Authenticated;
      // Preserve current avatar related fields from Authenticated state
      final List<String> currentDefaultAvatarUrls = authenticatedState.defaultAvatarUrls;
      final bool currentIsLoadingAvatars = authenticatedState.isLoadingAvatars;
      final String? currentAvatarFetchError = authenticatedState.avatarFetchError;

      // You might want a more specific loading state, e.g., ProfileUpdating
      // For now, re-using AuthLoading or simply proceeding.
      // emit(AuthLoading()); // Uncomment if you want a distinct loading state for this

      try {
        final updatedProfileMap = await _apiService.updateUserProfile(
          authenticatedState.token,
          username: username,
          bio: bio,
          pronouns: pronouns,
          chatAvailability: chatAvailability,
          avatarUrl: avatarUrl,
          isActive: isActive,
        );

        if (updatedProfileMap != null) {
          final updatedUser = User.fromJson(updatedProfileMap);
          emit(Authenticated(
            token: authenticatedState.token, 
            user: updatedUser,
            defaultAvatarUrls: currentDefaultAvatarUrls, // Preserve from before update
            isLoadingAvatars: currentIsLoadingAvatars,
            avatarFetchError: currentAvatarFetchError,
          ));
        } else {
          // API call returned null, indicating failure at API level
          emit(AuthFailure(
            "Failed to update profile. Please try again.",
            defaultAvatarUrls: currentDefaultAvatarUrls,
            isLoadingAvatars: currentIsLoadingAvatars,
            avatarFetchError: currentAvatarFetchError,
          ));
          // Revert to previous authenticated state, which already has its avatar fields
          emit(authenticatedState); 
        }
      } catch (e) {
        emit(AuthFailure(
          "Error updating profile: ${e.toString()}",
          defaultAvatarUrls: currentDefaultAvatarUrls,
          isLoadingAvatars: currentIsLoadingAvatars,
          avatarFetchError: currentAvatarFetchError,
        ));
        emit(authenticatedState); // Revert to previous state on error
      }
    } else {
      // Cannot update profile if not authenticated
      // Preserve current avatar state if any (though likely default if not authenticated)
      emit(AuthFailure("Cannot update profile: User not authenticated.", defaultAvatarUrls: state.defaultAvatarUrls, isLoadingAvatars: state.isLoadingAvatars, avatarFetchError: state.avatarFetchError));
    }
  }

  Future<void> deleteAccount() async {
    if (state is Authenticated) {
      final authenticatedState = state as Authenticated;
      // Preserve current avatar related fields from Authenticated state
      final List<String> currentDefaultAvatarUrls = authenticatedState.defaultAvatarUrls;
      final String? currentAvatarFetchError = authenticatedState.avatarFetchError;

      // Emit state indicating deletion is in progress
      // AuthDeletionInProgress constructor already takes super.defaultAvatarUrls etc.
      // So we pass them here.
      emit(AuthDeletionInProgress(token: authenticatedState.token, user: authenticatedState.user, defaultAvatarUrls: currentDefaultAvatarUrls, isLoadingAvatars: false, avatarFetchError: currentAvatarFetchError));

      try {
        final bool success = await _apiService.deleteCurrentUser(authenticatedState.token);

        if (success) {
          final prefs = await SharedPreferences.getInstance();
          await _clearAuthData(prefs); // Clear token and anonymousId locally
          // After deletion, avatar list should be reset for Unauthenticated state
          emit(Unauthenticated()); 
        } else {
          // API call returned false, indicating failure at API level
          emit(AuthDeletionFailure(
            "Failed to delete account. Please try again.", 
            token: authenticatedState.token, 
            user: authenticatedState.user,
            defaultAvatarUrls: currentDefaultAvatarUrls,
            isLoadingAvatars: false,
            avatarFetchError: currentAvatarFetchError,
          ));
        }
      } catch (e) {
        // Handle network or other errors
        emit(AuthDeletionFailure(
          "Error deleting account: ${e.toString()}", 
          token: authenticatedState.token, 
          user: authenticatedState.user,
          defaultAvatarUrls: currentDefaultAvatarUrls,
          isLoadingAvatars: false,
          avatarFetchError: currentAvatarFetchError,
        ));
      }
    } else {
      // Cannot delete account if not authenticated
      // Preserve current avatar state if any
      emit(AuthFailure("Cannot delete account: User not authenticated.", defaultAvatarUrls: state.defaultAvatarUrls, isLoadingAvatars: state.isLoadingAvatars, avatarFetchError: state.avatarFetchError));
    }
  }
}