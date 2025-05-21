import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/services/auth_api_service.dart'; // Assuming methods will be here
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:equatable/equatable.dart';

part 'data_erasure_state.dart';

class DataErasureCubit extends Cubit<DataErasureState> {
  final AuthApiService _authApiService;
  final AuthCubit _authCubit;

  DataErasureCubit({
    required AuthApiService authApiService,
    required AuthCubit authCubit,
  })  : _authApiService = authApiService,
        _authCubit = authCubit,
        super(DataErasureInitial());

  Future<void> _performErasure(
    String actionType,
    Future<bool> Function(String token) apiCall,
    String successMessage,
  ) async {
    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(DataErasureFailure(actionType, 'User not authenticated.'));
      return;
    }
    final token = authState.token;

    emit(DataErasureInProgress(actionType));
    try {
      final success = await apiCall(token);
      if (success) {
        emit(DataErasureSuccess(actionType, successMessage));
        // Optionally, trigger a refresh of relevant data elsewhere in the app
        // e.g., by calling methods on other cubits or emitting a global event.
      } else {
        emit(DataErasureFailure(actionType, 'Failed to erase $actionType. Please try again.'));
      }
    } catch (e) {
      emit(DataErasureFailure(actionType, 'An error occurred while erasing $actionType: ${e.toString()}'));
    }
  }

  Future<void> eraseMyPosts() async {
    await _performErasure(
      'posts',
      _authApiService.eraseAllMyPosts,
      'All your posts have been successfully erased.',
    );
  }

  Future<void> eraseMyComments() async {
    await _performErasure(
      'comments',
      _authApiService.eraseAllMyComments,
      'All your comments have been successfully erased.',
    );
  }

  Future<void> eraseMyChats() async {
    await _performErasure(
      'chats',
      _authApiService.eraseAllMyChatMessages,
      'All your chat messages have been successfully erased.',
    );
  }

  Future<void> eraseMyAccountInfo() async {
    await _performErasure(
      'all_info',
      _authApiService.eraseAllMyAccountInfo,
      'All your account information (posts, comments, chats) has been successfully erased.',
    );
  }
}