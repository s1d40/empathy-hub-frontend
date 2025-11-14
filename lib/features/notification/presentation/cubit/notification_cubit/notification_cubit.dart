import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:anonymous_hubs/core/services/notification_api_service.dart'; // New service
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/notification/data/models/notification_model.dart'; // New model
import 'package:anonymous_hubs/core/enums/notification_enums.dart'; // Import enums
import 'package:web_socket_channel/web_socket_channel.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationApiService _notificationApiService;
  final AuthCubit _authCubit;
  late StreamSubscription _authSubscription;

  WebSocketChannel? _channel;
  StreamSubscription? _notificationSubscription;

  NotificationCubit({
    required NotificationApiService notificationApiService,
    required AuthCubit authCubit,
  })  : _notificationApiService = notificationApiService,
        _authCubit = authCubit,
        super(NotificationInitial()) {
    _authSubscription = _authCubit.stream.listen((state) {
      if (state is Authenticated) {
        _connectWebSocket(state.token);
        fetchNotifications(); // Fetch notifications on login
      } else if (state is Unauthenticated) {
        _disconnectWebSocket();
        emit(NotificationInitial()); // Reset state on logout
      }
    });

    // If already authenticated on cubit creation (e.g., hot restart)
    if (_authCubit.state is Authenticated) {
      _connectWebSocket((_authCubit.state as Authenticated).token);
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    if (_authCubit.state is! Authenticated) {
      emit(const NotificationError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(NotificationLoading());
    try {
      final notifications = await _notificationApiService.getNotifications(token);
      if (notifications != null) {
        // Removed: await markAllNotificationsAsRead();
        // Removed: final updatedNotifications = notifications.map((n) => n.copyWith(status: NotificationStatus.read)).toList();
        final unreadCount = notifications.where((n) => n.status == NotificationStatus.unread).length;
        emit(NotificationLoaded(notifications: notifications, unreadCount: unreadCount));
      } else {
        emit(const NotificationError("Failed to load notifications."));
      }
    } catch (e) {
      emit(NotificationError("An error occurred: ${e.toString()}"));
    }
  }

  Future<void> openNotificationList() async {
    // First, fetch the latest notifications
    await fetchNotifications();
    // Then, mark all of them as read
    await markAllNotificationsAsRead();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (_authCubit.state is! Authenticated) {
      emit(const NotificationError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    try {
      final updatedNotification = await _notificationApiService.markNotificationAsRead(token, notificationId);

      if (updatedNotification != null && state is NotificationLoaded) {
        final loadedState = state as NotificationLoaded;
        final updatedList = loadedState.notifications.map((n) {
          return n.id == updatedNotification.id ? updatedNotification : n;
        }).toList();
        final unreadCount = updatedList.where((n) => n.status == NotificationStatus.unread).length;
        emit(loadedState.copyWith(notifications: updatedList, unreadCount: unreadCount));
      }
    } catch (e) {
      emit(NotificationError("An error occurred: ${e.toString()}"));
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (_authCubit.state is! Authenticated) {
      emit(const NotificationError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    try {
      final success = await _notificationApiService.markAllNotificationsAsRead(token);
      if (success && state is NotificationLoaded) {
        final loadedState = state as NotificationLoaded;
        final updatedList = loadedState.notifications.map((n) => n.copyWith(status: NotificationStatus.read)).toList();
        emit(loadedState.copyWith(notifications: updatedList, unreadCount: 0));
      }
    } catch (e) {
      emit(NotificationError("An error occurred: ${e.toString()}"));
    }
  }

  void _connectWebSocket(String token) {
    _disconnectWebSocket(); // Ensure any existing connection is closed

    try {
      final wsUrl = Uri.parse('${ApiConfig.baseWsUrl}/api/v1/notifications/ws?token=$token');
      _channel = WebSocketChannel.connect(wsUrl);
      print('Notification WebSocket connected to: $wsUrl');

      _notificationSubscription = _channel!.stream.listen(
        (message) {
          print('Notification WebSocket received: $message');
          final decodedMessage = json.decode(message);
          print('Decoded message: $decodedMessage');
          print('Message type: ${decodedMessage['type']}');
          print('Is new_notification type? ${decodedMessage['type'] == 'new_notification'}');
          print('Payload: ${decodedMessage['payload']}');
          if (decodedMessage['type'] == 'new_notification') {
            final notification = NotificationModel.fromJson(decodedMessage['payload']);
            print('Notification object from JSON: $notification');
            print('State before _addNotification: $state');
            _addNotification(notification);
            print('State after _addNotification: $state');
          }
        },
        onDone: () {
          print('Notification WebSocket disconnected.');
          // Optionally try to reconnect
        },
        onError: (error) {
          print('Notification WebSocket error: $error');
          // Optionally try to reconnect
        },
      );
    } catch (e) {
      print('Failed to connect Notification WebSocket: $e');
    }
  }

  void _disconnectWebSocket() {
    _notificationSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _notificationSubscription = null;
    print('Notification WebSocket disconnected.');
  }

  void _addNotification(NotificationModel newNotification) async {
    if (state is NotificationLoaded) {
      final loadedState = state as NotificationLoaded;
      final updatedList = [newNotification, ...loadedState.notifications];
      final unreadCount = updatedList.where((n) => n.status == NotificationStatus.unread).length;
      emit(loadedState.copyWith(notifications: updatedList, unreadCount: unreadCount));
    } else {
      // If not yet loaded, just emit a loaded state with the new notification
      emit(NotificationLoaded(notifications: [newNotification], unreadCount: 1));
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    _disconnectWebSocket();
    return super.close();
  }
}
