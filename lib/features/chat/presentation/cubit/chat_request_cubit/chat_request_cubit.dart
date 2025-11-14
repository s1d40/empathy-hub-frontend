import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/core/services/chat_api_service.dart';
import 'package:anonymous_hubs/features/chat/data/models/chat_request_model.dart';
import 'package:anonymous_hubs/features/chat/data/models/chat_room_model.dart'; // New: Import ChatRoom
import 'package:anonymous_hubs/features/notification/presentation/cubit/notification_cubit/notification_cubit.dart';
import 'package:anonymous_hubs/core/enums/notification_enums.dart' as NotifEnums; // Alias NotificationEnums
import 'package:anonymous_hubs/core/services/api_exception.dart'; // Import ApiException

part 'chat_request_state.dart';

class ChatRequestCubit extends Cubit<ChatRequestState> {
  final ChatApiService _chatApiService;
  final AuthCubit _authCubit;
  final NotificationCubit _notificationCubit;
  late StreamSubscription _authSubscription;
  StreamSubscription? _notificationSubscription;

  ChatRequestCubit({
    required ChatApiService chatApiService,
    required AuthCubit authCubit,
    required NotificationCubit notificationCubit,
  })  : _chatApiService = chatApiService,
        _authCubit = authCubit,
        _notificationCubit = notificationCubit,
        super(ChatRequestInitial()) {
    _authSubscription = _authCubit.stream.listen((state) {
      if (state is Authenticated) {
        fetchPendingChatRequests();
        _listenToNotifications();
      } else if (state is Unauthenticated) {
        _notificationSubscription?.cancel();
        emit(ChatRequestInitial());
      }
    });

    if (_authCubit.state is Authenticated) {
      fetchPendingChatRequests();
      _listenToNotifications();
    }
  }

  void _listenToNotifications() {
    _notificationSubscription?.cancel(); // Cancel previous subscription if any
    _notificationSubscription = _notificationCubit.stream.listen((notificationState) {
      if (notificationState is NotificationLoaded) {
        // Check for new chat request notifications
        final newChatRequests = notificationState.notifications.where(
          (n) => n.notificationType == NotifEnums.NotificationType.chatRequestReceived && n.status == NotifEnums.NotificationStatus.unread,
        ).toList();

        if (newChatRequests.isNotEmpty) {
          // A new chat request notification arrived, so refetch pending requests
          fetchPendingChatRequests();
        }
      }
    });
  }

  Future<void> fetchPendingChatRequests() async {
    if (_authCubit.state is! Authenticated) {
      emit(const ChatRequestError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatRequestLoading());
    try {
      final requests = await _chatApiService.getPendingChatRequests(token);
      if (requests != null) {
        emit(ChatRequestLoaded(
          pendingRequests: requests,
          pendingRequestCount: requests.length,
        ));
      } else {
        emit(const ChatRequestError("Failed to load chat requests."));
      }
    } catch (e) {
      emit(ChatRequestError("An error occurred: ${e.toString()}"));
    }
  }

  Future<void> acceptChatRequest(String requestId) async {
    if (_authCubit.state is! Authenticated) {
      emit(const ChatRequestError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatRequestActionInProgress(requestId));
    try {
      final newChatRoom = await _chatApiService.acceptChatRequest(token, requestId);
      if (newChatRoom != null) {
        emit(ChatRequestAcceptSuccess(newChatRoom));
        fetchPendingChatRequests(); // Refresh the list
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // If the request is not found (e.g., sender deleted account)
        if (state is ChatRequestLoaded) {
          final currentRequests = (state as ChatRequestLoaded).pendingRequests;
          final updatedRequests = currentRequests.where((req) => req.anonymousRequestId != requestId).toList();
          emit(ChatRequestLoaded(
            pendingRequests: updatedRequests,
            pendingRequestCount: updatedRequests.length,
          ));
        }
        emit(const ChatRequestActionFailure("Chat request no longer exists or has been withdrawn."));
        fetchPendingChatRequests(); // Re-sync with backend to be sure
      } else {
        emit(ChatRequestActionFailure("Failed to accept chat request: ${e.message}"));
      }
    } catch (e) {
      emit(ChatRequestActionFailure("Failed to accept chat request: ${e.toString()}"));
    }
  }

  Future<void> declineChatRequest(String requestId) async {
    if (_authCubit.state is! Authenticated) {
      emit(const ChatRequestError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(ChatRequestActionInProgress(requestId));
    try {
      final declinedChatRequest = await _chatApiService.declineChatRequest(token, requestId);
      if (declinedChatRequest != null) {
        emit(ChatRequestDeclineSuccess(declinedChatRequest));
        fetchPendingChatRequests(); // Refresh the list
      }
    } catch (e) {
      emit(ChatRequestActionFailure("Failed to decline chat request: ${e.toString()}"));
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    _notificationSubscription?.cancel();
    return super.close();
  }
}