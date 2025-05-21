import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/services/post_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart';
import 'package:equatable/equatable.dart';

part 'create_post_state.dart';

class CreatePostCubit extends Cubit<CreatePostState> {
  final AuthCubit _authCubit;
  final PostApiService _postApiService;

  CreatePostCubit({
    required AuthCubit authCubit,
    required PostApiService postApiService,
  })  : _authCubit = authCubit,
        _postApiService = postApiService,
        super(CreatePostInitial());

  Future<void> submitNewPost({required String content, String? title}) async {
    final currentAuthState = _authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(const CreatePostFailure('User not authenticated. Please sign in.'));
      return;
    }
    final String token = currentAuthState.token;
    print("[CreatePostCubit] Emitting CreatePostInProgress for title: '$title'");
    emit(CreatePostInProgress());

    try {
      print("[CreatePostCubit] Calling _postApiService.createPost...");
      final createdPostData = await _postApiService.createPost(
        token,
        content: content,
        title: title,
      );
      print("[CreatePostCubit] _postApiService.createPost returned: $createdPostData");

      if (createdPostData != null) {
        print("[CreatePostCubit] Attempting Post.fromJson with data: $createdPostData");
        final newPost = Post.fromJson(createdPostData);
        print("[CreatePostCubit] Post.fromJson successful. New post ID: ${newPost.id}, Title: ${newPost.title}");
        print("[CreatePostCubit] Emitting CreatePostSuccess");
        emit(CreatePostSuccess(newPost));
      } else {
        print("[CreatePostCubit] createdPostData is null. Emitting CreatePostFailure.");
        emit(const CreatePostFailure(
            'Failed to create post. API returned null.'));
      }
    } catch (e, stackTrace) {
      print("[CreatePostCubit] Caught exception during post creation: $e");
      print("[CreatePostCubit] Stack trace: $stackTrace");
      emit(CreatePostFailure('Error creating post: ${e.toString()}. Check console for details.'));
    }
  }

  void resetToInitial() {
    print("[CreatePostCubit] Resetting to CreatePostInitial");
    emit(CreatePostInitial());
  }
}