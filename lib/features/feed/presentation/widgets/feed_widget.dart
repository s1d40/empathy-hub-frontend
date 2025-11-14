import 'package:anonymous_hubs/features/feed/presentation/widgets/feed_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anonymous_hubs/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:anonymous_hubs/features/feed/presentation/cubit/post_item_cubit/post_item_cubit.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/core/services/post_api_service.dart';
import 'package:anonymous_hubs/features/feed/presentation/models/post_model.dart'; // Import the Post model


class FeedWidget extends StatefulWidget {
  // Consider if you need to pass any initial parameters, though usually not for a feed.
  const FeedWidget({super.key}); 

  @override
  State<FeedWidget> createState() => _FeedWidgetState();
}

class _FeedWidgetState extends State<FeedWidget> {
  final List<Post> _displayedItems = []; // Changed type to Post
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initial load is typically triggered when FeedCubit is created or by HomePage.
    // If FeedWidget is the one creating/providing FeedCubit, then:
    // context.read<FeedCubit>().loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The BlocBuilder should be the top-level widget returned by build.
    return BlocBuilder<FeedCubit, FeedState>(
      builder: (context, state) {
        if (state is FeedInitial) {
          // Trigger initial load now that FeedCubit is globally provided
          context.read<FeedCubit>().loadPosts(); 
          return const Center(child: Text("Initializing feed..."));
        }
        // Handle FeedLoading state:
        // If it's FeedLoading and there are no posts yet (initial load), show full spinner.
        // If it's FeedLoading but we already have posts (meaning we are loading more in the background
        // or a refresh was triggered while posts were visible), we'll fall through to the FeedLoaded logic
        // to keep displaying existing posts. The ListView builder will handle the "loading more" indicator.
        if (state is FeedLoading && (state is! FeedLoaded || (state as FeedLoaded).posts.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        // Handle FeedError state (only if no posts are currently loaded)
        if (state is FeedError && (state is! FeedLoaded || (state as FeedLoaded).posts.isEmpty)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${state.message}'),
                ElevatedButton(
                  onPressed: () => context.read<FeedCubit>().loadPosts(),
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        }
        // Handle FeedLoaded state, or FeedLoading/FeedError if posts are already available
        if (state is FeedLoaded || (state is FeedLoading && (state as FeedLoaded).posts.isNotEmpty) || (state is FeedError && (state as FeedLoaded).posts.isNotEmpty)) {
          
          List<Post> posts = [];
          bool hasReachedMax = true; // Default to true if not FeedLoaded
          
          if (state is FeedLoaded) {
            posts = state.posts;
            hasReachedMax = state.hasReachedMax;
          } else if (state is FeedLoading && (state as FeedLoaded).posts.isNotEmpty) {
            posts = (state as FeedLoaded).posts; // Show existing posts while loading more
            // hasReachedMax will be determined by the eventual FeedLoaded state
          } else if (state is FeedError && (state as FeedLoaded).posts.isNotEmpty) {
            posts = (state as FeedLoaded).posts; // Show existing posts even if there was an error loading more
          }
          final bool isLoadingMore = (state is FeedLoading && posts.isNotEmpty);

          if (posts.isEmpty && !isLoadingMore) { // Check isLoadingMore as well
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No posts yet. Be the first!'),
                  ElevatedButton(
                    onPressed: () => context.read<FeedCubit>().refreshPosts(),
                    child: const Text('Refresh'),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<FeedCubit>().refreshPosts(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: posts.length + (hasReachedMax || isLoadingMore ? 0 : 1),
              itemBuilder: (BuildContext context, int index) {
                if (index >= posts.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                }
                final post = posts[index];
                return BlocProvider<PostItemCubit>(
                  key: ValueKey(post.id), // Important for list item state
                  create: (_) => PostItemCubit(
                    authCubit: context.read<AuthCubit>(),
                    postApiService: context.read<PostApiService>(),
                    initialPost: post,
                  ),
                  // BlocListener for PostItemDeleted is better handled in HomePage or where FeedCubit is managed
                  child: const FeedItemWidget(), // FeedItemWidget now gets post from its own Cubit
                );
              },
            ),
          );
        }
        return const Center(child: Text("Something went wrong.")); // Fallback
      },
    );
  }

  void _onScroll() {
    if (_isBottom) {
      final feedState = context.read<FeedCubit>().state;
      if (feedState is FeedLoaded && !feedState.hasReachedMax) {
        context.read<FeedCubit>().loadMorePosts();
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger a bit before reaching the absolute bottom for a smoother experience
    return currentScroll >= (maxScroll * 0.9); 
  }
}