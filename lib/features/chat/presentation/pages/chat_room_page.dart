import 'package:anonymous_hubs/core/services/chat_api_service.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/chat/data/models/models.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_room_cubit/chat_room_cubit.dart';
import 'package:anonymous_hubs/features/chat/presentation/widgets/chat_message_bubble_widget.dart';
import 'package:anonymous_hubs/features/chat/presentation/widgets/message_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_list_cubit/chat_list_cubit.dart'; // Import ChatListCubit
import 'package:anonymous_hubs/features/chat/data/models/chat_participant_status_model.dart'; // New import

class ChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom; // Passed from ChatListPage or after accepting a request

  const ChatRoomPage({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markChatRoomAsRead(); // Mark as read when entering the chat room
  }

  Future<void> _markChatRoomAsRead() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      final token = authState.token;
      final chatApiService = context.read<ChatApiService>();
      await chatApiService.markChatRoomAsRead(token, widget.chatRoom.anonymousRoomId);
      // After marking as read, refresh the ChatListCubit to update unread counts
      context.read<ChatListCubit>().fetchChatRooms();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getChatRoomTitle(BuildContext context, ChatRoom chatRoom) {
    if (chatRoom.isGroup) {
      return chatRoom.name ?? 'Group Chat';
    }
    final currentUserState = context.read<AuthCubit>().state;
    if (currentUserState is Authenticated) {
      final currentUserId = currentUserState.user.anonymousId;
      final otherParticipant = chatRoom.participants.firstWhere(
        (p) => p.anonymousId != currentUserId,
        orElse: () => ChatParticipantStatus(anonymousId: '', username: 'Unknown'), // Changed to ChatParticipantStatus
      );
      return otherParticipant.username;
    }
    return 'Chat';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatRoomCubit(
        chatApiService: context.read<ChatApiService>(),
        authCubit: context.read<AuthCubit>(),
        roomAnonymousId: widget.chatRoom.anonymousRoomId,
        initialRoomDetails: widget.chatRoom,
      )..fetchInitialMessages(), // Fetch initial messages and connect WebSocket
      child: SafeArea(
        bottom: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_getChatRoomTitle(context, widget.chatRoom)),
            // TODO: Add online status indicator or other actions
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: BlocBuilder<ChatRoomCubit, ChatRoomState>(
                  builder: (context, state) {
                    //print('[ChatRoomPage] BlocBuilder received state: ${state.runtimeType}');
                    // Simplified initial loading check
                    if (state is ChatRoomInitial || state is ChatRoomLoadingMessages) {
                      //print('[ChatRoomPage] State is Initial or LoadingMessages. Showing spinner.');
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ChatRoomLoaded) {
                      //print('[ChatRoomPage] State is ChatRoomLoaded. Messages count: ${state.messages.length}, HasReachedMax: ${state.hasReachedMaxMessages}');
                      // If messages are empty AND we've confirmed there are no more pages to load (hasReachedMaxMessages is true)
                      // OR if messages are empty and it's not just the initial load (hasReachedMaxMessages is false but it's not the very first fetch)
                      // For simplicity, let's show "No messages" if the list is empty and we are sure there are no more.
                      if (state.messages.isEmpty && state.hasReachedMaxMessages) {
                         //print('[ChatRoomPage] ChatRoomLoaded: No messages and hasReachedMax. Showing "No messages yet".');
                         return const Center(child: Text('No messages yet. Say hi!'));
                      }                    
                      //print('[ChatRoomPage] ChatRoomLoaded: Building ListView with ${state.messages.length} messages.');
                      return NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          // Check if we are near the "top" of the reversed list (maxScrollExtent)
                          // and if there are more messages to load.
                          // The 'context' here is from the BlocBuilder, so it can find ChatRoomCubit.
                          if (!state.hasReachedMaxMessages &&
                              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 50.0 &&
                              scrollInfo is ScrollUpdateNotification) { // Optionally check for actual scroll
                            
                            // Prevent multiple rapid calls if already loading more
                            // (ChatRoomCubit's loadMoreMessages already has guards, but this is an extra check)
                            final cubit = context.read<ChatRoomCubit>();
                            if (cubit.state is ChatRoomLoaded && !(cubit.state as ChatRoomLoaded).hasReachedMaxMessages) {
                               //print("[ChatRoomPage] Scroll near top, attempting to load more messages.");
                               cubit.loadMoreMessages();
                            }
                          }
                          return false; // Return false to allow the notification to continue to bubble up.
                        },
                        child: ListView.builder(
                          controller: _scrollController, // Still useful for programmatic scrolling
                          reverse: true, // To show newest messages at the bottom
                          itemCount: state.messages.length + (state.hasReachedMaxMessages ? 0 : 1),
                          itemBuilder: (itemBuilderContext, index) { // Use a different context name to avoid confusion
                            // //print('[ChatRoomPage] itemBuilder called for index: $index'); // Can be very verbose
                            if (index == state.messages.length && !state.hasReachedMaxMessages) {
                              // This is the loading indicator for older messages
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (index >= state.messages.length) return const SizedBox.shrink();

                            final message = state.messages[index];
                            final authState = itemBuilderContext.read<AuthCubit>().state; // Use itemBuilderContext
                            bool isCurrentUser = false;
                            if (authState is Authenticated) {
                              isCurrentUser = message.senderAnonymousId == authState.user.anonymousId;
                            }
                            return ChatMessageBubbleWidget(
                              message: message,
                              isCurrentUser: isCurrentUser,
                            );
                          },
                        ),
                      );
                    } else if (state is ChatRoomError) {
                      //print('[ChatRoomPage] State is ChatRoomError: ${state.message}');
                      return Center(child: Text('Error: ${state.message}'));
                    }
                    // Fallback for other states like WebSocketConnecting, Disconnected, etc.
                    // You might want specific UI for these if they are distinct states.
                    //print('[ChatRoomPage] State is unhandled or fallback (${state.runtimeType}). Showing default text.');
                    return const Center(child: Text('Chat status unknown or connecting...'));
                  },
                ),
              ),
              BlocBuilder<ChatRoomCubit, ChatRoomState>( // To get isSending status
                builder: (context, state) {
                  bool isSending = state is ChatRoomLoaded && state.isSendingMessage;
                  return MessageInputWidget(
                    isSending: isSending,
                    onSendMessage: (content) {
                      context.read<ChatRoomCubit>().sendMessage(content);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}