import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/services/auth_api_service.dart';
import 'package:empathy_hub_app/core/services/user_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/user/data/models/user_models.dart'; // For UserSimple
import 'package:equatable/equatable.dart';

part 'user_interaction_lists_state.dart';

class UserInteractionListsCubit extends Cubit<UserInteractionListsState> {
  final AuthApiService _authApiService;
  final UserApiService _userApiService;
  final AuthCubit _authCubit;

  UserInteractionListsCubit({
    required AuthApiService authApiService,
    required UserApiService userApiService,
    required AuthCubit authCubit,
  })  : _authApiService = authApiService,
        _userApiService = userApiService,
        _authCubit = authCubit,
        super(UserInteractionListsInitial());

  Future<void> fetchMutedUsers() async {
    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(const MutedUsersError("User not authenticated."));
      return;
    }
    emit(MutedUsersLoading());
    try {
      final users = await _authApiService.listMutedUsers(authState.token);
      if (users != null) {
        emit(MutedUsersLoaded(users));
      } else {
        emit(const MutedUsersError("Failed to fetch muted users."));
      }
    } catch (e) {
      emit(MutedUsersError("Error fetching muted users: ${e.toString()}"));
    }
  }

  Future<void> fetchBlockedUsers() async {
    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(const BlockedUsersError("User not authenticated."));
      return;
    }
    emit(BlockedUsersLoading());
    try {
      final users = await _authApiService.listBlockedUsers(authState.token);
      if (users != null) {
        emit(BlockedUsersLoaded(users));
      } else {
        emit(const BlockedUsersError("Failed to fetch blocked users."));
      }
    } catch (e) {
      emit(BlockedUsersError("Error fetching blocked users: ${e.toString()}"));
    }
  }

  Future<void> unmuteUser(String targetUserId, String username) async {
    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(UserUnmuteFailure(targetUserId, username, "User not authenticated."));
      return;
    }
    emit(UserUnmuting(targetUserId));
    try {
      final success = await _userApiService.unmuteUser(authState.token, targetUserId);
      if (success) {
        emit(UserUnmuteSuccess(targetUserId, username));
        // Optionally, re-fetch the muted users list
        // fetchMutedUsers(); // Or let the UI decide to refresh
      } else {
        emit(UserUnmuteFailure(targetUserId, username, "Failed to unmute user."));
      }
    } catch (e) {
      emit(UserUnmuteFailure(targetUserId, username, "Error unmuting user: ${e.toString()}"));
    }
  }

  Future<void> unblockUser(String targetUserId, String username) async {
    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(UserUnblockFailure(targetUserId, username, "User not authenticated."));
      return;
    }
    emit(UserUnblocking(targetUserId));
    try {
      final success = await _userApiService.unblockUser(authState.token, targetUserId);
      if (success) {
        emit(UserUnblockSuccess(targetUserId, username));
        // Optionally, re-fetch the blocked users list
        // fetchBlockedUsers(); // Or let the UI decide to refresh
      } else {
        emit(UserUnblockFailure(targetUserId, username, "Failed to unblock user."));
      }
    } catch (e) {
      emit(UserUnblockFailure(targetUserId, username, "Error unblocking user: ${e.toString()}"));
    }
  }
}