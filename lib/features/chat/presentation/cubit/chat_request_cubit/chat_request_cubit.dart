import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/services/chat_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/chat/data/models/models.dart';
import 'package:equatable/equatable.dart';

part 'chat_request_state.dart';

class ChatRequestCubit extends Cubit<ChatRequestState> {
  final ChatApiService _chatApiService;
  final AuthCubit _authCubit;

  // Could add pagination limit if API supports it and it's needed
  // static const int _requestsLimit = 20;

  ChatRequestCubit({
    required ChatApiService chatApiService,
    required AuthCubit authCubit,
  })  : _chatApiService = chatApiService,
        _authCubit = authCubit,
        super(ChatRequestInitial());

  Future<void> fetchPendingRequests() async {
    if (_authCubit.state is! Authenticated) {
      emit(const ChatRequestError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatRequestLoading());
    try {
      // Assuming getPendingChatRequests handles pagination if implemented
      final requests = await _chatApiService.getPendingChatRequests(token);

      if (requests != null) {
        emit(ChatRequestLoaded(requests));
      } else {
        emit(const ChatRequestError("Failed to load pending chat requests."));
      }
    } catch (e) {
      // Log the full technical error for developers
      print("ChatRequestCubit: Error fetching pending requests: ${e.toString()}");

      String userFriendlyMessage;
      if (e.toString().contains("404")) {
        userFriendlyMessage = "Could not retrieve chat requests at this time. This feature might be temporarily unavailable.";
      } else if (e.toString().toLowerCase().contains("network") || e.toString().toLowerCase().contains("socketexception")) {
        userFriendlyMessage = "A network error occurred. Please check your connection and try again.";
      } else {
        userFriendlyMessage = "An error occurred while fetching requests. Please try again later.";
      }
      emit(ChatRequestError(userFriendlyMessage));
    }
  }

  Future<void> acceptRequest(String requestAnonymousId) async {
    if (_authCubit.state is! Authenticated) {
      emit(ChatRequestActionFailure("User not authenticated.", requestAnonymousId));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatRequestActionInProgress(requestAnonymousId));
    try {
      final newChatRoom = await _chatApiService.acceptChatRequest(token, requestAnonymousId);

      if (newChatRoom != null) {
        emit(ChatRequestAcceptSuccess(newChatRoom, requestAnonymousId));
        // After success, refresh the list of pending requests
        // or manually remove the accepted request from the current list if ChatRequestLoaded
        if (state is ChatRequestLoaded || state is ChatRequestAcceptSuccess || state is ChatRequestDeclineSuccess) {
          // To ensure the list is up-to-date, re-fetch.
          // A more optimized way would be to remove it from the current list in ChatRequestLoaded.
          fetchPendingRequests();
        }
      } else {
        emit(ChatRequestActionFailure("Failed to accept chat request.", requestAnonymousId));
      }
    } catch (e) {
      emit(ChatRequestActionFailure("Error accepting request: ${e.toString()}", requestAnonymousId));
    }
  }

  Future<void> declineRequest(String requestAnonymousId) async {
    if (_authCubit.state is! Authenticated) {
      emit(ChatRequestActionFailure("User not authenticated.", requestAnonymousId));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatRequestActionInProgress(requestAnonymousId));
    try {
      final declinedRequest = await _chatApiService.declineChatRequest(token, requestAnonymousId);

      if (declinedRequest != null) {
        emit(ChatRequestDeclineSuccess(declinedRequest));
        // After success, refresh the list of pending requests
        // or manually remove the declined request from the current list if ChatRequestLoaded
         if (state is ChatRequestLoaded || state is ChatRequestAcceptSuccess || state is ChatRequestDeclineSuccess) {
          // To ensure the list is up-to-date, re-fetch.
          fetchPendingRequests();
        }
      } else {
        emit(ChatRequestActionFailure("Failed to decline chat request.", requestAnonymousId));
      }
    } catch (e) {
      emit(ChatRequestActionFailure("Error declining request: ${e.toString()}", requestAnonymousId));
    }
  }
}