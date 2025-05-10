import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:empathy_hub_app/features/auth/presentation/models/user_model.dart'; // Import the User model

part 'auth_state.dart'; // Links to the state file

class AuthCubit extends Cubit<AuthState> {
  // You might inject an AuthService here later
  // final AuthService _authService;
  static const String _anonymousIdKey = 'anonymous_user_id';
  static const String _usernameKey = 'chosen_username'; // Made key more specific
  final Uuid _uuid = const Uuid();

  AuthCubit(/*this._authService*/) : super(AuthInitial());

  // Example method: In MVP, this might be called on app startup
  // to generate/retrieve an anonymous ID.
  Future<void> checkAuthenticationStatus() async {
    try {
      emit(AuthLoading());
      // Simulate fetching/generating anonymous ID
      await Future.delayed(const Duration(milliseconds: 500)); // Reduced delay for quicker startup
      
      // For MVP, let's assume local storage interaction.
      // Your roadmap (source:110, source:112) mentions auto-generated IDs stored locally.
      //String? storedAnonymousId = await _getStoredAnonymousId(); // Placeholder
      final prefs = await SharedPreferences.getInstance();
      String? storedAnonymousId = prefs.getString(_anonymousIdKey);
      String? storedUsername = prefs.getString(_usernameKey);

      if (storedAnonymousId != null) {
        if (storedUsername != null){
          final user = User(
            id: storedAnonymousId,
            username: storedUsername,
          );
          emit(AuthSuccess(user));
        } else { // storedUsername is null
          emit(AuthRequiresUsername(storedAnonymousId));
        }
      } else {
        // No anonymous ID found, generate a new one and require username selection
        String newAnonymousId = _generateNewAnonymousId();
        await prefs.setString(_anonymousIdKey, newAnonymousId);
        // print("AuthCubit: Stored new anonymous ID: $newAnonymousId");
        emit(AuthRequiresUsername(newAnonymousId));
      }

    } catch (e) {
      // For MVP, perhaps just default to a new ID generation or simple failure state
      emit(AuthFailure("Failed to check/initialize auth: ${e.toString()}"));
      // Or, always generate a new ID on failure to ensure app can proceed
      // String newAnonymousId = _generateNewAnonymousId();
      // await _storeAnonymousId(newAnonymousId);
      // emit(AuthSuccess(newAnonymousId));
    }
  }

  // Note: _getStoredAnonymousId and _storeAnonymousId are effectively inlined
  // into checkAuthenticationStatus now for simplicity, but you could keep them
  // separate if you prefer.
  // Future<String?> _getStoredAnonymousId() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final id = prefs.getString(_anonymousIdKey);
  //   // print("AuthCubit: Checked for stored anonymous ID. Found: $id");
  //   return id;
  // }
  //
  // Future<void> _storeAnonymousId(String id) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(_anonymousIdKey, id);
  //   // print("AuthCubit: Stored anonymous ID: $id");
  // }
  
  String _generateNewAnonymousId() {
    final newId = _uuid.v4();
    // print("AuthCubit: Generated new anonymous ID: $newId");
    return newId;
  }

  // Method to handle account deletion (clearing ID) as per roadmap (source:119)
  Future<void> deleteAnonymousAccount() async {
    emit(AuthLoading());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_anonymousIdKey);
    await prefs.remove(_usernameKey); // Also remove the username
    // print("AuthCubit: Deleted anonymous ID from local storage.");
    // TODO: Notify backend to delete/anonymize associated data
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate
    emit(AuthInitial()); // Or some specific 'AccountDeleted' state then AuthInitial
    // After deletion, app might re-trigger checkAuthenticationStatus or generate a new ID
    // For now, let's re-trigger checkAuthenticationStatus to get a new ID and prompt for username
    // checkAuthenticationStatus(); // Or let the UI handle re-initiation
  }

  // Renamed from submitUsername and now accepts a User object
  Future<void> completeUsernameSelection(User user) async {
    emit(AuthLoading());
    // Basic validation
    if (user.username.trim().isEmpty) {
      emit(AuthFailure("Username cannot be empty."));
      // Re-emit AuthRequiresUsername so the user can try again
      // It's important to pass the user.id (which is the anonymousId) back
      emit(AuthRequiresUsername(user.id)); 
      return;
    }
    // In a real app, you might add more validation or check uniqueness against a backend here.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, user.username.trim());
    // print("AuthCubit: Stored username: ${user.username} for anonymousId: ${user.id}");
    emit(AuthSuccess(user));
  }
}