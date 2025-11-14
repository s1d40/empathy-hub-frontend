import 'package:bloc/bloc.dart';
import 'package:anonymous_hubs/core/services/auth_api_service.dart';
import 'package:anonymous_hubs/core/services/user_api_service.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/user/data/models/user_models.dart';
import 'package:equatable/equatable.dart';

part 'user_interaction_state.dart';

class UserInteractionCubit extends Cubit<UserInteractionState> {
  final UserApiService _userApiService;
  final AuthApiService _authApiService;
  final AuthCubit _authCubit;

  UserInteractionCubit({
    required UserApiService userApiService,
    required AuthApiService authApiService,
    required AuthCubit authCubit,
  })  : _userApiService = userApiService,
        _authApiService = authApiService,
        _authCubit = authCubit,
        super(UserInteractionInitial());

  Future<void> loadUserInteractionStatus(String targetUserAnonymousId) async {
    emit(UserInteractionStatusLoading());
    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(const UserInteractionStatusLoadFailure(message: "User not authenticated."));
      return;
    }
    final token = authState.token;

    try {
      final mutedUsersList = await _authApiService.listMutedUsers(token);
      final blockedUsersList = await _authApiService.listBlockedUsers(token);

      bool isMuted = false;
      if (mutedUsersList != null) {
        isMuted = mutedUsersList.any((user) => user.anonymousId == targetUserAnonymousId);
      }

      bool isBlocked = false;
      if (blockedUsersList != null) {
        isBlocked = blockedUsersList.any((user) => user.anonymousId == targetUserAnonymousId);
      }

      emit(UserInteractionStatusLoaded(
        isMuted: isMuted,
        isBlocked: isBlocked,
        targetUserAnonymousId: targetUserAnonymousId,
      ));
    } catch (e) {
      emit(UserInteractionStatusLoadFailure(message: "Failed to load interaction status: ${e.toString()}"));
    }
  }

  Future<void> _performAction({
    required String targetUserAnonymousId,
    required Future<dynamic> Function(String token, String targetId) apiCall,
    required String actionName,
  }) async {
    bool currentMuteStatus = false;
    bool currentBlockStatus = false;

    if (state is UserInteractionStatusLoaded) {
      final loadedState = state as UserInteractionStatusLoaded;
      if (loadedState.targetUserAnonymousId == targetUserAnonymousId) {
        currentMuteStatus = loadedState.isMuted;
        currentBlockStatus = loadedState.isBlocked;
      }
    } else if (state is UserInteractionActionFailure) {
        final failureState = state as UserInteractionActionFailure;
        if (failureState.targetUserAnonymousId == targetUserAnonymousId) {
            currentMuteStatus = failureState.previousMuteStatus;
            currentBlockStatus = failureState.previousBlockStatus;
        }
    }

    emit(UserInteractionActionInProgress(
      wasMuted: currentMuteStatus,
      wasBlocked: currentBlockStatus,
      targetUserAnonymousId: targetUserAnonymousId,
    ));

    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(UserInteractionActionFailure(
        message: "User not authenticated.",
        previousMuteStatus: currentMuteStatus,
        previousBlockStatus: currentBlockStatus,
        targetUserAnonymousId: targetUserAnonymousId,
      ));
      return;
    }
    final token = authState.token;

    try {
      final result = await apiCall(token, targetUserAnonymousId);
      // For DELETE operations (unmute/unblock), result is bool.
      // For POST operations (mute/block), result is UserRelationshipRead or null.
      if (result != null && (result is bool && result == true || result is UserRelationshipRead)) {
        // Successfully performed action, reload status
        await loadUserInteractionStatus(targetUserAnonymousId);
      } else {
        // If result is bool and false, or null for POSTs
        emit(UserInteractionActionFailure(
          message: "Failed to $actionName user.",
          previousMuteStatus: currentMuteStatus,
          previousBlockStatus: currentBlockStatus,
          targetUserAnonymousId: targetUserAnonymousId,
        ));
      }
    } catch (e) {
      emit(UserInteractionActionFailure(
        message: "Error $actionName user: ${e.toString()}",
        previousMuteStatus: currentMuteStatus,
        previousBlockStatus: currentBlockStatus,
        targetUserAnonymousId: targetUserAnonymousId,
      ));
    }
  }

  Future<void> muteUser(String targetUserAnonymousId) async {
    await _performAction(
      targetUserAnonymousId: targetUserAnonymousId,
      apiCall: _userApiService.muteUser,
      actionName: "mute",
    );
  }

  Future<void> unmuteUser(String targetUserAnonymousId) async {
    await _performAction(
      targetUserAnonymousId: targetUserAnonymousId,
      apiCall: (token, targetId) => _userApiService.unmuteUser(token, targetId), // Ensure it matches signature
      actionName: "unmute",
    );
  }

  Future<void> blockUser(String targetUserAnonymousId) async {
    await _performAction(
      targetUserAnonymousId: targetUserAnonymousId,
      apiCall: _userApiService.blockUser,
      actionName: "block",
    );
  }

  Future<void> unblockUser(String targetUserAnonymousId) async {
    await _performAction(
      targetUserAnonymousId: targetUserAnonymousId,
      apiCall: (token, targetId) => _userApiService.unblockUser(token, targetId), // Ensure it matches signature
      actionName: "unblock",
    );
  }

  // Call this method to reset the state, e.g., when navigating away from a profile
  void resetState() {
    emit(UserInteractionInitial());
  }
}