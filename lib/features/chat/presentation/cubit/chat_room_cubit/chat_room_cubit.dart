import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/config/api_config.dart'; // For WebSocket URL
import 'package:empathy_hub_app/core/services/chat_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/chat/data/models/models.dart';
import 'package:equatable/equatable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'chat_room_state.dart';

class ChatRoomCubit extends Cubit<ChatRoomState> {
  final ChatApiService _chatApiService;
  final AuthCubit _authCubit;
  final String roomAnonymousId;
  final ChatRoom? initialRoomDetails; // Optional: if passed from chat list

  static const int _messagesLimit = 30; // Number of messages to fetch per page

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  ChatRoomCubit({
    required ChatApiService chatApiService,
    required AuthCubit authCubit,
    required this.roomAnonymousId,
    this.initialRoomDetails,
  })  : _chatApiService = chatApiService,
        _authCubit = authCubit,
        super(ChatRoomInitial());

  Future<void> fetchInitialMessages() async {
    if (_authCubit.state is! Authenticated) {
      emit(const ChatRoomError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatRoomLoadingMessages());
    try {
      final messages = await _chatApiService.getChatMessages(
        token,
        roomAnonymousId,
        limit: _messagesLimit,
      );

      if (messages != null) {
        //print('[ChatRoomCubit] Fetched ${messages.length} messages from service.');
        // API typically returns oldest first, so no need to reverse for initial load if ListView is reversed.
        //print('[ChatRoomCubit] Emitting ChatRoomLoaded with ${messages.length} messages (oldest first).');
        emit(ChatRoomLoaded(
          messages: messages, // Keep API order (oldest first)
          hasReachedMaxMessages: messages.length < _messagesLimit,
          roomDetails: initialRoomDetails, // Use initial if provided
        ));
        // After fetching initial messages, connect to WebSocket
        connectWebSocket();
      } else {
        //print('[ChatRoomCubit] Failed to load messages, service returned null.');
        emit(const ChatRoomError("Failed to load messages."));
      }
    } catch (e) {
      final errorMessage = "An error occurred while loading messages: ${e.toString()}";
      //print('[ChatRoomCubit] $errorMessage');
      emit(ChatRoomError(errorMessage));
    }
  }

  Future<void> loadMoreMessages() async {
    if (state is! ChatRoomLoaded || (_authCubit.state is! Authenticated)) return;

    final loadedState = state as ChatRoomLoaded;
    if (loadedState.hasReachedMaxMessages) return;

    final token = (_authCubit.state as Authenticated).token;

    try {
      final newMessages = await _chatApiService.getChatMessages(
        token,
        roomAnonymousId,
        skip: loadedState.messages.length,
        limit: _messagesLimit,
      );

      if (newMessages != null) {
        emit(loadedState.copyWith(
          messages: [...newMessages, ...loadedState.messages], // Prepend older messages (API gives them oldest first)
          hasReachedMaxMessages: newMessages.length < _messagesLimit,
        ));
      } else {
        // Optionally emit a specific error for loading more, or just log
        //print("Failed to load more messages.");
      }
    } catch (e) {
      //print("Error loading more messages: ${e.toString()}");
    }
  }

  void connectWebSocket() {
    if (_authCubit.state is! Authenticated) {
      emit(const ChatRoomError("Cannot connect to WebSocket: User not authenticated."));
      return;
    }
    if (_channel != null && _channelSubscription != null && !(_channelSubscription!.isPaused)) {
      //print("WebSocket already connected or connecting.");
      return; // Already connected or connecting
    }

    final token = (_authCubit.state as Authenticated).token;
    final wsBaseUrl = ApiConfig.baseWsUrl; // Assuming ApiConfig has baseWsUrl like 'ws://127.0.0.1:8000'
    // Corrected WebSocket URL path
    final url = Uri.parse('$wsBaseUrl/api/v1/chats/ws/$roomAnonymousId?token=$token');

    // IMPORTANT: Capture the messages and details from the current state if it's ChatRoomLoaded.
    // This is because fetchInitialMessages emits ChatRoomLoaded, then calls this.
    // We will emit ChatRoomWebSocketConnecting, then transition back to ChatRoomLoaded
    // preserving the messages.
    List<ChatMessage> messagesToPreserve = [];
    bool hasReachedMaxToPreserve = false;
    ChatRoom? roomDetailsToPreserve = initialRoomDetails; // Start with initial details

    if (state is ChatRoomLoaded) {
      final loadedState = state as ChatRoomLoaded;
      messagesToPreserve = loadedState.messages;
      hasReachedMaxToPreserve = loadedState.hasReachedMaxMessages;
      roomDetailsToPreserve = loadedState.roomDetails; // Use details from the fully loaded state
      //print("[ChatRoomCubit connectWebSocket] Preserving ${messagesToPreserve.length} messages from current ChatRoomLoaded state.");
    } else {
      //print("[ChatRoomCubit connectWebSocket] Current state is ${state.runtimeType}, not ChatRoomLoaded. Preserved messages will be empty if this is the first load sequence.");
    }

    emit(ChatRoomWebSocketConnecting());
    _channel = WebSocketChannel.connect(url);
    // Now, emit ChatRoomLoaded with the connection status and the *preserved* messages
    //print("[ChatRoomCubit connectWebSocket] Emitting ChatRoomLoaded (connected) with ${messagesToPreserve.length} messages.");
    emit(ChatRoomLoaded(
      messages: messagesToPreserve,
      hasReachedMaxMessages: hasReachedMaxToPreserve,
      roomDetails: roomDetailsToPreserve,
      isWebSocketConnected: true, // Mark as connected
    ));

    _channelSubscription = _channel!.stream.listen(
      (message) {
        try {
          //print("[ChatRoomCubit _channel.stream.listen] Received raw message: $message");
          final decodedMessage = json.decode(message as String);
          if (decodedMessage['type'] == 'new_message') {
            final chatMessage = ChatMessage.fromJson(decodedMessage['payload'] as Map<String, dynamic>);
            
            // Ensure we are updating a ChatRoomLoaded state, or creating one if necessary
            if (state is ChatRoomLoaded) {
              final currentState = state as ChatRoomLoaded;
              //print("[ChatRoomCubit connectWebSocket] Received new message. Current state is ChatRoomLoaded. Adding to existing ${currentState.messages.length} messages.");
              // Append new message to the end of the list
              // TEST: Try prepending to see if it fixes the visual order issue
              emit(currentState.copyWith(messages: [chatMessage, ...currentState.messages]));
            } else {
              // This might happen if a message arrives very quickly after connection
              // or if the state was something else (e.g., ChatRoomSendingMessage, though less likely now with the fix below)
              // We should transition to ChatRoomLoaded with this new message.
              // We'd need to know 'hasReachedMax' and 'roomDetails' ideally.
              // For simplicity, if not ChatRoomLoaded, we'll assume it's a fresh load with this one message.
              //print("[ChatRoomCubit connectWebSocket] Received new message. Current state is ${state.runtimeType}. Transitioning to ChatRoomLoaded with this message.");
              emit(ChatRoomLoaded(messages: [chatMessage], isWebSocketConnected: true, roomDetails: initialRoomDetails));
            }
          }
          // Handle other message types if any (e.g., 'error', 'user_joined')
        } catch (e) {
          //print("Error processing WebSocket message: $e");
        }
      },
      onError: (error) {
        //print("WebSocket error: $error");
        // Preserve messages when transitioning to disconnected state
        List<ChatMessage> currentMessagesOnError = [];
        bool currentHasReachedMaxOnError = false;
        ChatRoom? currentRoomDetailsOnError = initialRoomDetails;
        if (state is ChatRoomLoaded) { // If error happened while already loaded
            final s = state as ChatRoomLoaded;
            currentMessagesOnError = s.messages;
            currentHasReachedMaxOnError = s.hasReachedMaxMessages;
            currentRoomDetailsOnError = s.roomDetails;
        } else { // If error occurred from a non-loaded state (e.g. connecting)
            currentMessagesOnError = messagesToPreserve; // Use messages captured at start of connectWebSocket
            currentHasReachedMaxOnError = hasReachedMaxToPreserve;
            currentRoomDetailsOnError = roomDetailsToPreserve;
        }
        
        //print("[ChatRoomCubit connectWebSocket] WebSocket onError. Emitting ChatRoomLoaded with isWebSocketConnected: false and ${currentMessagesOnError.length} messages.");
        emit(ChatRoomWebSocketDisconnected(reason: error.toString()));
        if (state is ChatRoomLoaded) {
          emit((state as ChatRoomLoaded).copyWith(isWebSocketConnected: false, messages: currentMessagesOnError, hasReachedMaxMessages: currentHasReachedMaxOnError, roomDetails: currentRoomDetailsOnError));
        } else {
           emit(ChatRoomLoaded(messages: currentMessagesOnError, hasReachedMaxMessages: currentHasReachedMaxOnError, roomDetails: currentRoomDetailsOnError, isWebSocketConnected: false));
        }
      },
      onDone: () {
        //print("WebSocket connection closed.");
        List<ChatMessage> currentMessagesOnDone = [];
        bool currentHasReachedMaxOnDone = false;
        ChatRoom? currentRoomDetailsOnDone = initialRoomDetails;
        if (state is ChatRoomLoaded) {
            final s = state as ChatRoomLoaded;
            currentMessagesOnDone = s.messages;
            currentHasReachedMaxOnDone = s.hasReachedMaxMessages;
            currentRoomDetailsOnDone = s.roomDetails;
        } else { // If onDone occurred from a non-loaded state
            currentMessagesOnDone = messagesToPreserve;
            currentHasReachedMaxOnDone = hasReachedMaxToPreserve;
            currentRoomDetailsOnDone = roomDetailsToPreserve;
        }
        emit(const ChatRoomWebSocketDisconnected(reason: "Connection closed by server or client."));
         if (state is ChatRoomLoaded) {
          emit((state as ChatRoomLoaded).copyWith(isWebSocketConnected: false, messages: currentMessagesOnDone, hasReachedMaxMessages: currentHasReachedMaxOnDone, roomDetails: currentRoomDetailsOnDone));
        } else {
          emit(ChatRoomLoaded(messages: currentMessagesOnDone, hasReachedMaxMessages: currentHasReachedMaxOnDone, roomDetails: currentRoomDetailsOnDone, isWebSocketConnected: false));
        }
      },
    );
  }

  void sendMessage(String content) {
    if (_channel == null || (_authCubit.state is! Authenticated)) {
      emit(ChatRoomMessageSendFailed(content, "WebSocket not connected or user not authenticated."));
      return;
    }
    // Emit ChatRoomSendingMessage, but ensure we have the current messages to revert to ChatRoomLoaded
    List<ChatMessage> currentMessages = [];
    bool currentHasReachedMax = false; // Default if not loaded
    ChatRoom? currentRoomDetails = initialRoomDetails;

    if (state is ChatRoomLoaded) {
      final loadedState = state as ChatRoomLoaded;
      currentMessages = loadedState.messages;
      currentHasReachedMax = loadedState.hasReachedMaxMessages;
      currentRoomDetails = loadedState.roomDetails;
    }
    
    emit(const ChatRoomSendingMessage()); // UI can show a spinner or disable input
    final messageToSend = WebSocketChatMessage(content: content);
    _channel!.sink.add(json.encode(messageToSend.toJson()));
    // Transition back to ChatRoomLoaded almost immediately. The actual new message will arrive via the WebSocket stream.
    // This prevents the UI from getting stuck on "ChatRoomSendingMessage".
    emit(ChatRoomLoaded(messages: currentMessages, hasReachedMaxMessages: currentHasReachedMax, roomDetails: currentRoomDetails, isWebSocketConnected: true));
  }

  @override
  Future<void> close() {
    _channelSubscription?.cancel();
    _channel?.sink.close();
    return super.close();
  }
}