import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:anonymous_hubs/core/config/api_config.dart'; // For WebSocket URL
import 'package:anonymous_hubs/core/services/chat_api_service.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/chat/data/models/models.dart';
import 'package:equatable/equatable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package
import 'package:anonymous_hubs/features/chat/data/models/message_status_enum.dart'; // Import MessageStatus enum

part 'chat_room_state.dart';

class ChatRoomCubit extends Cubit<ChatRoomState> {
  final ChatApiService _chatApiService;
  final AuthCubit _authCubit;
  final String roomAnonymousId;
  final ChatRoom? initialRoomDetails; // Optional: if passed from chat list

  static const int _messagesLimit = 30; // Number of messages to fetch per page
  final Uuid _uuid = const Uuid(); // Initialize Uuid

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  // Reconnection logic
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectBaseDelay = Duration(seconds: 2); // Initial delay
  Timer? _reconnectTimer;

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
        // Mark the chat room as read after successfully loading messages and connecting WebSocket
        _chatApiService.markChatRoomAsRead(token, roomAnonymousId);
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
    final url = Uri.parse('$wsBaseUrl/api/v1/chat/ws/$roomAnonymousId?token=$token');

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
          final webSocketMessage = WebSocketMessage.fromJson(decodedMessage);
          if (state is! ChatRoomLoaded) {
            // If not in loaded state, just log and ignore for now, or re-evaluate state transition
            // print("Received WebSocket message but not in ChatRoomLoaded state: ${webSocketMessage.type}");
            return;
          }

          final currentState = state as ChatRoomLoaded;
          final currentUserId = (_authCubit.state as Authenticated).user.anonymousId;

          if (webSocketMessage.type == 'new_message') {
            final receivedChatMessage = ChatMessage.fromJson(webSocketMessage.payload);
            
            // Check if this is a confirmation of a pending message from the current user
            if (receivedChatMessage.senderAnonymousId == currentUserId && receivedChatMessage.clientMessageId != null) {
              final int index = currentState.messages.indexWhere(
                (msg) => msg.clientMessageId == receivedChatMessage.clientMessageId && msg.status == MessageStatus.pending
              );

              if (index != -1) {
                // Replace the pending message with the confirmed message
                final updatedMessages = List<ChatMessage>.from(currentState.messages);
                updatedMessages[index] = receivedChatMessage.copyWith(status: MessageStatus.sent);
                emit(currentState.copyWith(messages: updatedMessages));
                return;
              }
            }
            // If not a confirmation of a pending message, or from another user, just prepend
            emit(currentState.copyWith(messages: [receivedChatMessage, ...currentState.messages]));
          } else if (webSocketMessage.type == 'error') {
            final errorPayload = webSocketMessage.payload as Map<String, dynamic>;
            final clientMessageId = errorPayload['clientMessageId'] as String?;
            final errorMessage = errorPayload['detail'] as String? ?? "Unknown error";

            if (clientMessageId != null) {
              // Find the pending message and mark it as failed
              final int index = currentState.messages.indexWhere(
                (msg) => msg.clientMessageId == clientMessageId && msg.status == MessageStatus.pending
              );
              if (index != -1) {
                final updatedMessages = List<ChatMessage>.from(currentState.messages);
                updatedMessages[index] = updatedMessages[index].copyWith(status: MessageStatus.failed);
                emit(currentState.copyWith(messages: updatedMessages));
                emit(ChatRoomError("Message failed: $errorMessage")); // Also show a general error
                return;
              }
            }
            emit(ChatRoomError("WebSocket Error: $errorMessage"));
          }
          // Handle other message types if any (e.g., 'user_joined')
        } catch (e) {
          //print("Error processing WebSocket message: $e");
          emit(ChatRoomError("Failed to process WebSocket message: ${e.toString()}"));
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

  void _attemptReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = _reconnectBaseDelay * _reconnectAttempts; // Exponential backoff
      emit(ChatRoomWebSocketReconnecting(attempt: _reconnectAttempts, delay: delay));
      _reconnectTimer = Timer(delay, () {
        connectWebSocket();
      });
    } else {
      emit(const ChatRoomWebSocketDisconnected(reason: "Max reconnection attempts reached."));
    }
  }

  void sendMessage(String content) {
    if (_channel == null || (_authCubit.state is! Authenticated)) {
      emit(ChatRoomMessageSendFailed(content, "WebSocket not connected or user not authenticated."));
      return;
    }
    
    final authenticatedState = _authCubit.state as Authenticated;
    final currentUser = authenticatedState.user; // Assuming AuthCubit provides the current user

    if (currentUser == null) {
      emit(ChatRoomMessageSendFailed(content, "Current user details not available."));
      return;
    }

    // Emit ChatRoomLoaded with isSendingMessage: true to disable input
    if (state is ChatRoomLoaded) {
      emit((state as ChatRoomLoaded).copyWith(isSendingMessage: true));
    } else {
      // If not in ChatRoomLoaded state, we can't set isSendingMessage,
      // but the MessageInputWidget should already be disabled if not loaded.
    }

    final clientMessageId = _uuid.v4(); // Generate a client-side UUID

    final pendingMessage = ChatMessage(
      content: content,
      anonymousMessageId: null, // Server ID is not yet known
      clientMessageId: clientMessageId, // Use client-generated ID
      chatroomAnonymousId: roomAnonymousId,
      senderAnonymousId: currentUser.anonymousId,
      timestamp: DateTime.now(),
      sender: UserSimple(
        anonymousId: currentUser.anonymousId,
        username: currentUser.username!, // Use null-check operator
        avatarUrl: currentUser.avatarUrl,
      ),
      status: MessageStatus.pending, // Set status to pending
    );

    // Optimistically add the message to the UI
    List<ChatMessage> updatedMessages = [];
    if (state is ChatRoomLoaded) {
      final currentState = state as ChatRoomLoaded;
      updatedMessages = [pendingMessage, ...currentState.messages];
      emit(currentState.copyWith(messages: updatedMessages, isSendingMessage: false)); // Reset isSendingMessage
    } else {
      // If not in ChatRoomLoaded state, this might be an edge case,
      // but we should still try to display the message.
      updatedMessages = [pendingMessage];
      emit(ChatRoomLoaded(messages: updatedMessages, isWebSocketConnected: true, roomDetails: initialRoomDetails, isSendingMessage: false)); // Reset isSendingMessage
    }
    
    final messageToSend = WebSocketChatMessage(
      anonymousMessageId: clientMessageId, // Include client-generated ID
      content: content,
    );
    _channel!.sink.add(json.encode(messageToSend.toJson()));
  }

  @override
  Future<void> close() {
    _channelSubscription?.cancel();
    _channel?.sink.close();
    return super.close();
  }
}