import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/feed/presentation/cubit/post_item_cubit/post_item_cubit.dart';
import 'package:anonymous_hubs/core/services/post_api_service.dart';
import 'package:anonymous_hubs/features/feed/presentation/models/post_model.dart';
import 'package:anonymous_hubs/features/feed/presentation/widgets/feed_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserProfilePostsListWidget extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final String? error;

  const UserProfilePostsListWidget({
    super.key,
    required this.posts,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Error loading posts: $error'));
    }
    if (posts.isEmpty) {
      return const Center(child: Text('This user has not made any posts yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0), // Keep padding from original
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return BlocProvider(
          create: (_) => PostItemCubit(
            initialPost: post,
            postApiService: context.read<PostApiService>(),
            authCubit: context.read<AuthCubit>(),
          ),
          child: const FeedItemWidget(),
        );
      },
    );
  }
}