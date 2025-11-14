import 'package:bloc/bloc.dart';
import 'package:anonymous_hubs/core/services/chat_api_service.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/chat/data/models/models.dart';
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
      final ChatInitiationResponse? response = await _chatApiService.initiateDirectChatOrRequest(
        token,
        chatInitiateData,
      );

      if (response != null) {
        if (response.chatRoom != null) {
          emit(ChatInitiationSuccessRoom(response.chatRoom!, chatInitiateData.targetUserAnonymousId));
        } else if (response.chatRequest != null) {
          emit(ChatInitiationSuccessRequest(
            response.chatRequest!,
            chatInitiateData.targetUserAnonymousId,
            isExistingRequest: response.isExisting, // Pass the isExisting flag
          ));
        } else {
          // This case should ideally not be reached if ChatInitiationResponse is constructed correctly
          emit(ChatInitiationFailure("Unexpected empty response from chat initiation.", targetUserAnonymousId: chatInitiateData.targetUserAnonymousId));
        }
      } else {
        // This case handles if the API service returned null due to an API error (e.g., 403, 404)
        emit(ChatInitiationFailure("Failed to initiate chat. The user may not be available or does not exist.", targetUserAnonymousId: chatInitiateData.targetUserAnonymousId));
      }
    } catch (e) {
      // Handles exceptions from the HTTP call itself (network errors, etc.)
      emit(ChatInitiationFailure("An error occurred: ${e.toString()}", targetUserAnonymousId: chatInitiateData.targetUserAnonymousId));
    }
  }
}