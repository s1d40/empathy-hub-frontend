import 'package:anonymous_hubs/core/services/chat_api_service.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/chat/data/models/chat_room_model.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_list_cubit/chat_list_cubit.dart';
import 'package:anonymous_hubs/features/chat/presentation/widgets/chat_list_item_widget.dart';
import 'package:anonymous_hubs/features/chat/presentation/widgets/chat_request_item_widget.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_request_cubit/chat_request_cubit.dart';
import 'package:anonymous_hubs/features/chat/presentation/pages/chat_room_page.dart';
import 'package:anonymous_hubs/features/notification/presentation/cubit/notification_cubit/notification_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatListPage extends StatefulWidget {
  final int? initialTabIndex;
  final List<ChatRoom> chatRooms;

  const ChatListPage({
    super.key,
    this.initialTabIndex,
    required this.chatRooms,
  });

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.anonymousId : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chats'),
                  if (widget.chatRooms.where((room) => room.unreadCount(currentUserId) > 0).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${widget.chatRooms.where((room) => room.unreadCount(currentUserId) > 0).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            BlocBuilder<ChatRequestCubit, ChatRequestState>(
              builder: (context, chatRequestState) {
                int pendingRequestCount = 0;
                if (chatRequestState is ChatRequestLoaded) {
                  pendingRequestCount = chatRequestState.pendingRequestCount;
                }
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Requests'),
                      if (pendingRequestCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '$pendingRequestCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(context),
          _buildRequestsTab(context),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildChatsTab(BuildContext context) {
    if (widget.chatRooms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No chats yet. Start a conversation!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatListCubit>().fetchChatRooms();
      },
      child: ListView.builder(
        itemCount: widget.chatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = widget.chatRooms[index];
          return ChatListItemWidget(
            chatRoom: chatRoom,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatRoomPage(chatRoom: chatRoom),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab(BuildContext context) {
    return BlocConsumer<ChatRequestCubit, ChatRequestState>(
      listener: (context, state) {
        if (state is ChatRequestAcceptSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat request accepted! Opening chat...')),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatRoomPage(chatRoom: state.newChatRoom),
            ),
          );
        } else if (state is ChatRequestDeclineSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat request from ${state.declinedChatRequest.requester.username} declined.')),
          );
        } else if (state is ChatRequestActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: ${state.message}'), backgroundColor: Colors.redAccent),
          );
        }
      },
      builder: (context, state) {
        if (state is ChatRequestInitial || (state is ChatRequestLoading && !(state is ChatRequestLoaded))) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ChatRequestLoaded) {
          if (state.pendingRequests.isEmpty) {
            return const Center(child: Text("No pending chat requests."));
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ChatRequestCubit>().fetchPendingChatRequests();
            },
            child: ListView.builder(
              itemCount: state.pendingRequests.length,
              itemBuilder: (context, index) {
                final request = state.pendingRequests[index];
                final currentCubitState = context.watch<ChatRequestCubit>().state;
                bool isLoadingThisItem = currentCubitState is ChatRequestActionInProgress &&
                                         currentCubitState.requestAnonymousId == request.anonymousRequestId;

                return Opacity(
                  opacity: isLoadingThisItem ? 0.5 : 1.0,
                  child: ChatRequestItemWidget(
                    request: request,
                    onAccept: isLoadingThisItem ? () {} : () => context.read<ChatRequestCubit>().acceptChatRequest(request.anonymousRequestId),
                    onDecline: isLoadingThisItem ? () {} : () => context.read<ChatRequestCubit>().declineChatRequest(request.anonymousRequestId),
                  ),
                );
              },
            ),
          );
        } else if (state is ChatRequestActionInProgress) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)));
        } else if (state is ChatRequestError) {
          return Center(child: Text('Error loading requests: ${state.message}'));
        } else if (state is ChatRequestActionFailure) {
          return Center(child: Text('An error occurred: ${state.message}. Please pull to refresh or try again.'));
        }
        return const Center(child: Text('Manage your chat requests here.'));
      },
    );
  }
}
