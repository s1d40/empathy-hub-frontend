import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/home/presentation/pages/home_page.dart';
import 'package:anonymous_hubs/features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:anonymous_hubs/features/chat/presentation/pages/chat_list_page.dart';
import 'package:anonymous_hubs/features/feed/presentation/pages/post_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anonymous_hubs/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:anonymous_hubs/core/services/post_api_service.dart';
import 'package:anonymous_hubs/features/feed/presentation/models/post_model.dart';
import 'package:anonymous_hubs/features/navigation/presentation/widgets/app_drawer.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_list_cubit/chat_list_cubit.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_request_cubit/chat_request_cubit.dart';
import 'package:anonymous_hubs/features/notification/presentation/cubit/notification_cubit/notification_cubit.dart';
import 'package:anonymous_hubs/features/notification/data/models/notification_model.dart' as NotifModel;
import 'package:anonymous_hubs/core/enums/notification_enums.dart' as NotifEnums;

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int? _chatInitialTabIndex;

  static const List<String> _widgetTitles = <String>[
    'Feed',
    'AI Pal',
    'Chat',
  ];

  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().fetchNotifications();
    context.read<ChatListCubit>().fetchChatRooms();
    context.read<ChatRequestCubit>().fetchPendingChatRequests();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 2) {
        _chatInitialTabIndex = null;
      }
    });
  }

  void _handleNotificationTap(NotifModel.NotificationModel notification) async {
    final cubit = context.read<NotificationCubit>();
    if (notification.status == NotifEnums.NotificationStatus.unread) {
      cubit.markNotificationAsRead(notification.id);
    }

    switch (notification.notificationType) {
      case NotifEnums.NotificationType.chatRequestReceived:
        setState(() {
          _selectedIndex = 2;
          _chatInitialTabIndex = 1;
        });
        break;
      case NotifEnums.NotificationType.newCommentOnPost:
        if (notification.resourceId != null) {
          try {
            final postApiService = context.read<PostApiService>();
            final token = context.read<AuthCubit>().state is Authenticated
                ? (context.read<AuthCubit>().state as Authenticated).token
                : null;
            if (token == null) return;
            final Map<String, dynamic>? postData = await postApiService.getPostByAnonymousId(token, notification.resourceId!);
            final Post? post = postData != null ? Post.fromJson(postData) : null;
            if (post != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostDetailsPage(post: post),
                ),
              );
            }
          } catch (e) {
            // Handle error
          }
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is Authenticated ? authState.user.anonymousId : '';

    return BlocBuilder<ChatListCubit, ChatListState>(
      builder: (context, chatListState) {
        int totalUnreadChatCount = 0;
        if (chatListState is ChatListLoaded) {
          totalUnreadChatCount = chatListState.chatRooms.where((room) => room.unreadCount(currentUserId) > 0).length;
        }

        final List<Widget> widgetOptions = <Widget>[
          const HomePage(),
          const AIChatPage(),
          ChatListPage(
            initialTabIndex: _chatInitialTabIndex,
            chatRooms: chatListState is ChatListLoaded ? chatListState.chatRooms : [],
          ),
        ];

        return SafeArea(
          bottom: true,
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(_widgetTitles[_selectedIndex]),
              leading: IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              actions: <Widget>[
                BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, notificationState) {
                    int totalUnreadNotifications = 0;
                    List<NotifModel.NotificationModel> notifications = [];
                    if (notificationState is NotificationLoaded) {
                      totalUnreadNotifications = notificationState.unreadCount;
                      notifications = notificationState.notifications;
                    }
                    return PopupMenuButton<String>(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_none_outlined),
                          if (totalUnreadNotifications > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  '$totalUnreadNotifications',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                        ],
                      ),
                      onSelected: (String value) {
                        final cubit = context.read<NotificationCubit>();
                        if (cubit.state is NotificationLoaded) {
                          final notification = (cubit.state as NotificationLoaded).notifications.firstWhere((n) => n.id == value);
                          _handleNotificationTap(notification);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        if (notifications.isEmpty) {
                          return [
                            const PopupMenuItem<String>(
                              value: 'no_notifications',
                              enabled: false,
                              child: Text('No new notifications'),
                            ),
                          ];
                        }
                        return notifications.map((notification) {
                          return PopupMenuItem<String>(
                            value: notification.id,
                            child: Text(
                              notification.content,
                              style: TextStyle(
                                fontWeight: notification.status == NotifEnums.NotificationStatus.unread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList();
                      },
                    );
                  },
                ),
                if (_selectedIndex == 0) ...[
                  IconButton(icon: const Icon(Icons.search_outlined), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined),
                    tooltip: 'Refresh Feed',
                    onPressed: () {
                      context.read<FeedCubit>().refreshPosts();
                    },
                  ),
                  IconButton(icon: const Icon(Icons.filter_list_alt), onPressed: () {}),
                ]
              ],
            ),
            body: Center(
              child: widgetOptions.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dynamic_feed),
                  label: 'Feed',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.psychology_alt),
                  label: 'AI Pal',
                ),
                BottomNavigationBarItem(
                  icon: BlocBuilder<ChatRequestCubit, ChatRequestState>(
                    builder: (context, chatRequestState) {
                      int pendingRequestCount = 0;
                      if (chatRequestState is ChatRequestLoaded) {
                        pendingRequestCount = chatRequestState.pendingRequestCount;
                      }
                      return Stack(
                        children: [
                          const Icon(Icons.chat_bubble_outline),
                          if (totalUnreadChatCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  '$totalUnreadChatCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          if (pendingRequestCount > 0)
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  '$pendingRequestCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  label: 'Chat',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              onTap: _onItemTapped,
            ),
            drawer: const AppDrawer(),
          ),
        );
      },
    );
  }
}
