import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:anonymous_hubs/core/services/chat_api_service.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/chat/data/models/models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'chat_list_state.dart';

class ChatListCubit extends Cubit<ChatListState> {
  final ChatApiService _chatApiService;
  final AuthCubit _authCubit;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  StreamSubscription? _authSubscription;

  ChatListCubit({
    required ChatApiService chatApiService,
    required AuthCubit authCubit,
  })  : _chatApiService = chatApiService,
        _authCubit = authCubit,
        super(ChatListInitial()) {
    _authSubscription = _authCubit.stream.listen((authState) {
      if (authState is Authenticated) {
        fetchChatRooms();
        connectWebSocket(authState.token);
      } else if (authState is Unauthenticated) {
        disconnectWebSocket();
        emit(ChatListInitial());
      }
    });

    // Initial check
    if (_authCubit.state is Authenticated) {
      final token = (_authCubit.state as Authenticated).token;
      fetchChatRooms();
      connectWebSocket(token);
    }
  }

  Future<void> fetchChatRooms() async {
    if (_authCubit.state is! Authenticated) return;
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatListLoading());
    try {
      final rooms = await _chatApiService.getChatRooms(token);
      if (rooms != null) {
        emit(ChatListLoaded(chatRooms: rooms));
      } else {
        emit(const ChatListError("Failed to load chat rooms."));
      }
    } catch (e) {
      emit(ChatListError("An error occurred: ${e.toString()}"));
    }
  }

  void connectWebSocket(String token) {
    disconnectWebSocket(); // Ensure any existing connection is closed

    final wsBaseUrl = ApiConfig.baseWsUrl;
    final url = Uri.parse('$wsBaseUrl/api/v1/chat/ws-updates?token=$token');
    
    _channel = WebSocketChannel.connect(url);
    _channelSubscription = _channel!.stream.listen(
      (message) {
        final decodedMessage = json.decode(message as String);
        final webSocketMessage = WebSocketMessage.fromJson(decodedMessage);

        if (state is ChatListLoaded) {
          final currentState = state as ChatListLoaded;
          if (webSocketMessage.type == 'new_chat_room') {
            final newRoom = ChatRoom.fromJson(webSocketMessage.payload);
            final updatedRooms = [newRoom, ...currentState.chatRooms];
            emit(currentState.copyWith(chatRooms: updatedRooms));
          } else if (webSocketMessage.type == 'chat_update') {
            // This is a simple implementation. A more robust one would be to update the specific chat room.
            fetchChatRooms();
          }
        }
      },
      onError: (error) {
        // Handle error, maybe schedule a reconnect
      },
      onDone: () {
        // Handle connection closed, maybe schedule a reconnect
      },
    );
  }

  void disconnectWebSocket() {
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _channelSubscription = null;
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    disconnectWebSocket();
    return super.close();
  }
}
