import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/services/chat_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/chat/data/models/models.dart';
import 'package:equatable/equatable.dart';

part 'chat_list_state.dart';

class ChatListCubit extends Cubit<ChatListState> {
  final ChatApiService _chatApiService;
  final AuthCubit _authCubit;

  static const int _chatRoomsLimit = 20; // Number of chat rooms to fetch per page

  ChatListCubit({
    required ChatApiService chatApiService,
    required AuthCubit authCubit,
  })  : _chatApiService = chatApiService,
        _authCubit = authCubit,
        super(ChatListInitial());

  Future<void> fetchChatRooms({bool isRefresh = false}) async {
    if (_authCubit.state is! Authenticated) {
      emit(const ChatListError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    if (isRefresh) {
      emit(ChatListInitial()); // Reset to initial to show loading for refresh
    }

    // If it's loading more, we don't want to show full screen loading
    // The UI should handle showing a loading indicator at the bottom of the list
    if (state is! ChatListLoaded || isRefresh) {
      emit(ChatListLoading());
    }

    try {
      int currentPage = 0;
      List<ChatRoom> currentChatRooms = [];

      if (state is ChatListLoaded && !isRefresh) {
        final loadedState = state as ChatListLoaded;
        currentChatRooms = List.from(loadedState.chatRooms);
        // Calculate next page based on current items and limit
        currentPage = (currentChatRooms.length / _chatRoomsLimit).floor();
        if (loadedState.hasReachedMax) {
          // Already loaded all items, no need to fetch more
          return;
        }
      }

      final newChatRooms = await _chatApiService.getChatRooms(
        token,
        skip: currentPage * _chatRoomsLimit,
        limit: _chatRoomsLimit,
      );

      if (newChatRooms != null) {
        final bool hasReachedMax = newChatRooms.length < _chatRoomsLimit;
        final allChatRooms = isRefresh ? newChatRooms : (currentChatRooms + newChatRooms);
        
        // A simple way to remove duplicates if any, based on anonymousRoomId
        final uniqueChatRooms = Map.fromEntries(allChatRooms.map((e) => MapEntry(e.anonymousRoomId, e))).values.toList();

        emit(ChatListLoaded(chatRooms: uniqueChatRooms, hasReachedMax: hasReachedMax));
      } else {
        emit(const ChatListError("Failed to load chat rooms."));
      }
    } catch (e) {
      emit(ChatListError("An error occurred: ${e.toString()}"));
    }
  }
}