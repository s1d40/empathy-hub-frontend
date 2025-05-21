import 'package:empathy_hub_app/core/services/chat_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/chat/presentation/cubit/chat_list_cubit/chat_list_cubit.dart';
import 'package:empathy_hub_app/features/chat/presentation/widgets/chat_list_item_widget.dart';
import 'package:empathy_hub_app/features/chat/presentation/widgets/chat_request_item_widget.dart';
import 'package:empathy_hub_app/features/chat/presentation/cubit/chat_request_cubit/chat_request_cubit.dart';
import 'package:empathy_hub_app/features/chat/presentation/pages/chat_room_page.dart'; // We'll create this next
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 tabs: Chats and Requests
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatListCubit(
        chatApiService: context.read<ChatApiService>(),
        authCubit: context.read<AuthCubit>(),
      )..fetchChatRooms(), // Fetch rooms when the Cubit is created
      // No need for DefaultTabController here if we manage _tabController manually
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'), // Changed title for clarity
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Chats'),
              Tab(text: 'Requests'),
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
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildChatsTab(BuildContext context) {
    // This BlocBuilder is for the ChatListCubit which is provided above the Scaffold
    return BlocBuilder<ChatListCubit, ChatListState>(
      builder: (context, state) {
        if (state is ChatListLoading && state is! ChatListLoaded) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ChatListLoaded) {
          if (state.chatRooms.isEmpty) {
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
              context.read<ChatListCubit>().fetchChatRooms(isRefresh: true);
            },
            child: ListView.builder(
              itemCount: state.chatRooms.length + (state.hasReachedMax ? 0 : 1),
              itemBuilder: (context, index) {
                if (index >= state.chatRooms.length) {
                  if (!state.hasReachedMax) {
                    context.read<ChatListCubit>().fetchChatRooms();
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final chatRoom = state.chatRooms[index];
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
        } else if (state is ChatListError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('Welcome to Chats!'));
      },
    );
  }

  Widget _buildRequestsTab(BuildContext context) {
    return BlocProvider<ChatRequestCubit>(
      create: (context) => ChatRequestCubit(
        chatApiService: context.read<ChatApiService>(),
        authCubit: context.read<AuthCubit>(),
      )..fetchPendingRequests(),
      child: BlocConsumer<ChatRequestCubit, ChatRequestState>(
        listener: (context, state) {
          if (state is ChatRequestAcceptSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chat request accepted! Opening chat...')),
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
            if (state.requests.isEmpty) {
              return const Center(child: Text("No pending chat requests."));
            }
            return ListView.builder(
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                final currentCubitState = context.watch<ChatRequestCubit>().state;
                bool isLoadingThisItem = currentCubitState is ChatRequestActionInProgress &&
                                         currentCubitState.requestAnonymousId == request.anonymousRequestId;

                return Opacity(
                  opacity: isLoadingThisItem ? 0.5 : 1.0,
                  child: ChatRequestItemWidget(
                    request: request,
                    onAccept: isLoadingThisItem ? () {} : () => context.read<ChatRequestCubit>().acceptRequest(request.anonymousRequestId),
                    onDecline: isLoadingThisItem ? () {} : () => context.read<ChatRequestCubit>().declineRequest(request.anonymousRequestId),
                  ),
                );
              },
            );
          } else if (state is ChatRequestActionInProgress) {
             // Show a general loading indicator while an action is in progress and the list might be temporarily unavailable
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)));
          } else if (state is ChatRequestError) {
            return Center(child: Text('Error loading requests: ${state.message}'));
          } else if (state is ChatRequestActionFailure) {
            return Center(child: Text('An error occurred: ${state.message}. Please pull to refresh or try again.'));
          }
          return const Center(child: Text('Manage your chat requests here.'));
        },
      ),
    );
  }
}