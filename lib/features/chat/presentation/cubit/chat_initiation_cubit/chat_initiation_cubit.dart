import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/services/chat_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/chat/data/models/models.dart';
import 'package:equatable/equatable.dart';

part 'chat_initiation_state.dart';

class ChatInitiationCubit extends Cubit<ChatInitiationState> {
  final ChatApiService _chatApiService;
  final AuthCubit _authCubit;

  ChatInitiationCubit({
    required ChatApiService chatApiService,
    required AuthCubit authCubit,
  })  : _chatApiService = chatApiService,
        _authCubit = authCubit,
        super(ChatInitiationInitial());

  Future<void> initiateChat(ChatInitiate chatInitiateData) async {
    if (_authCubit.state is! Authenticated) {
      emit(ChatInitiationFailure("User not authenticated.", targetUserAnonymousId: chatInitiateData.targetUserAnonymousId));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatInitiationInProgress());

    try {
      final dynamic response = await _chatApiService.initiateDirectChatOrRequest(
        token,
        chatInitiateData,
      );

      if (response is ChatRoom) {
        emit(ChatInitiationSuccessRoom(response, chatInitiateData.targetUserAnonymousId));
      } else if (response is ChatRequest) {
        emit(ChatInitiationSuccessRequest(response, chatInitiateData.targetUserAnonymousId));
      } else if (response == null) {
        // This case handles if the API service returned null due to an API error (e.g., 403, 404)
        // We might want to extract the actual error message from ChatApiService if it returns it
        emit(ChatInitiationFailure("Failed to initiate chat. The user may not be available or does not exist.", targetUserAnonymousId: chatInitiateData.targetUserAnonymousId));
      } else {
        // Should not happen if ChatApiService is implemented correctly
        emit(ChatInitiationFailure("Unexpected response type during chat initiation.", targetUserAnonymousId: chatInitiateData.targetUserAnonymousId));
      }
    } catch (e) {
      // Handles exceptions from the HTTP call itself (network errors, etc.)
      emit(ChatInitiationFailure("An error occurred: ${e.toString()}", targetUserAnonymousId: chatInitiateData.targetUserAnonymousId));
    }
  }
}