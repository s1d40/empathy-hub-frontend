import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/auth/presentation/models/user_model.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/cubit/user_profile_cubit.dart';
import 'package:anonymous_hubs/core/services/user_api_service.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/widgets/user_profile_header_widget.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/cubit/user_interaction_cubit.dart'; // Import UserInteractionCubit
import 'package:anonymous_hubs/features/user_profile/presentation/widgets/user_profile_chat_button_widget.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/widgets/user_profile_posts_list_widget.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/widgets/user_profile_comments_list_widget.dart';

import 'package:anonymous_hubs/core/enums/app_enums.dart'; // For ReportedItemType
import 'package:anonymous_hubs/features/report/presentation/cubit/report_cubit.dart'; // Import ReportCubit
import 'package:anonymous_hubs/core/services/auth_api_service.dart'; // Import AuthApiService for UserInteractionCubit
import 'package:anonymous_hubs/features/report/presentation/widgets/report_dialog_widget.dart'; // Import ReportDialogWidget
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting
class UserProfilePage extends StatefulWidget {
  final String userAnonymousId;

  const UserProfilePage({super.key, required this.userAnonymousId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}
class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 tabs: Posts and Comments
    // Fetch user profile data when the page is initialized
    context
        .read<UserProfileCubit>() // Reads UserProfileCubit from the context provided by createUserProfilePageWithCubit
        .fetchUserProfileData(widget.userAnonymousId); 
    // Fetch user interaction status
    context
        .read<UserInteractionCubit>() // Reads UserInteractionCubit from the context
        .loadUserInteractionStatus(widget.userAnonymousId);
  }

  @override
  void dispose() {
    // Optionally reset cubit state if needed, though it might be handled by BlocProvider disposal
    // context.read<UserInteractionCubit>().resetState(); 
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            if (state is UserProfileLoaded) {
              return Text(state.user.username ?? 'User Profile');
            }
            return const Text('User Profile');
          },
        ), // Ensures title's BlocBuilder is closed
        actions: <Widget>[
          BlocBuilder<UserProfileCubit, UserProfileState>(
            builder: (context, state) {
              if (state is UserProfileLoaded) {
                final authState = context.watch<AuthCubit>().state;
                // Do not show report button for the current user's own profile
                if (authState is Authenticated && authState.user.anonymousId == state.user.anonymousId) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: Icon(Icons.report_problem_outlined, color: Colors.orangeAccent.shade700),
                  tooltip: 'Report User',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => BlocProvider.value(
                        value: BlocProvider.of<ReportCubit>(context), // Assuming ReportCubit is provided above
                        child: ReportDialogWidget(
                          itemType: ReportedItemType.user,
                          itemAnonymousId: state.user.anonymousId, // Use anonymousId from User model
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink(); // Don't show if profile not loaded
            },
          ), // Ensures the BlocBuilder within actions is closed
        ], // Ensures the actions list is closed
      ), // Ensures the AppBar itself is closed
      body: BlocListener<UserInteractionCubit, UserInteractionState>(
        listener: (context, state) {
          if (state is UserInteractionActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
          // Optionally, show success messages for mute/block actions
          // if (state is UserInteractionStatusLoaded && state.actionJustCompleted) { // You'd need to add a flag for this
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(content: Text('Action successful!')),
          //   );
          // }
        },
        child: BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, userProfileState) {
            if (userProfileState is UserProfileInitial || userProfileState is UserProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (userProfileState is UserProfileError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${userProfileState.message}', textAlign: TextAlign.center),
                ),
              );
            }
            if (userProfileState is UserProfileLoaded) {
              final user = userProfileState.user;
              final authState = context.watch<AuthCubit>().state;
              bool isOwnProfile = false;
              if (authState is Authenticated) {
                isOwnProfile = authState.user.anonymousId == user.anonymousId;
              }

              return NestedScrollView( // Use NestedScrollView for AppBar that scrolls with content
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, // For chat button to stretch
                          children: <Widget>[
                            UserProfileHeaderWidget(user: user),
                            const SizedBox(height: 16),
                            Text(
                              'Member since: ${DateFormat.yMMMd().format(user.createdAt.toLocal())}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (user.bio != null && user.bio!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Bio:', style: Theme.of(context).textTheme.titleSmall),
                              Text(user.bio!, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                            if (user.pronouns != null && user.pronouns!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Pronouns: ${user.pronouns}', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Chat Availability: ${user.chatAvailability.replaceAll('_', ' ').capitalizeFirstOfEach()}', // Use string directly
                              style: Theme.of(context).textTheme.bodyMedium
                            ),
                            const SizedBox(height: 16),
                            if (!isOwnProfile) ...[
                               UserProfileChatButtonWidget(profileUser: user),
                               const SizedBox(height: 16),
                              _buildInteractionButtons(context, user.anonymousId),
                              const SizedBox(height: 8),
                            ] else ... [
                              // Potentially "Edit Profile" button for own profile
                              ElevatedButton.icon(
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Profile'),
                                onPressed: () {
                                  // TODO: Navigate to EditProfilePage
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Edit Profile - To be implemented')),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ]
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Posts'),
                            Tab(text: 'Comments'),
                          ],
                        ),
                      ),
                      pinned: true, // Make the TabBar stick at the top when scrolling
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    UserProfilePostsListWidget(
                      posts: userProfileState.posts,
                      isLoading: userProfileState.postsLoading,
                      error: userProfileState.postsError,
                    ),
                    UserProfileCommentsListWidget(
                      comments: userProfileState.comments,
                      isLoading: userProfileState.commentsLoading,
                      error: userProfileState.commentsError,
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Something went wrong. Please try again.'));
          },
        ),
      ),
    );
  }

  Widget _buildInteractionButtons(BuildContext context, String targetUserAnonymousId) {
    return BlocBuilder<UserInteractionCubit, UserInteractionState>(
      builder: (context, state) {
        bool isMuted = false;
        bool isBlocked = false;
        bool isLoading = state is UserInteractionStatusLoading || state is UserInteractionActionInProgress;

        if (state is UserInteractionStatusLoaded) {
          isMuted = state.isMuted;
          isBlocked = state.isBlocked;
        } else if (state is UserInteractionActionInProgress) {
          // While action is in progress, reflect the state *before* the action
          isMuted = state.wasMuted;
          isBlocked = state.wasBlocked;
        } else if (state is UserInteractionActionFailure) {
          // On failure, reflect the state *before* the failed action
          isMuted = state.previousMuteStatus;
          isBlocked = state.previousBlockStatus;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: isLoading ? const SizedBox(width:18, height: 18, child: CircularProgressIndicator(strokeWidth: 2,)) : Icon(isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined),
                label: Text(isMuted ? 'Unmute' : 'Mute'),
                onPressed: isLoading ? null : () {
                  if (isMuted) {
                    context.read<UserInteractionCubit>().unmuteUser(targetUserAnonymousId);
                  } else {
                    context.read<UserInteractionCubit>().muteUser(targetUserAnonymousId);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: isMuted ? Colors.grey : Theme.of(context).colorScheme.secondary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: isLoading ? const SizedBox(width:18, height: 18, child: CircularProgressIndicator(strokeWidth: 2,)) : Icon(isBlocked ? Icons.block_flipped : Icons.block),
                label: Text(isBlocked ? 'Unblock' : 'Block'),
                onPressed: isLoading ? null : () {
                  if (isBlocked) {
                    context.read<UserInteractionCubit>().unblockUser(targetUserAnonymousId);
                  } else {
                    context.read<UserInteractionCubit>().blockUser(targetUserAnonymousId);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? Colors.red.shade300 : Colors.red.shade700),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Helper to provide the UserProfileCubit when navigating to this page
Widget createUserProfilePageWithCubit(String userAnonymousId) {
  // This function should directly return the MultiBlocProvider
  // which will then provide the necessary Cubits to the UserProfilePage.
  return MultiBlocProvider(
    providers: [
      BlocProvider<UserProfileCubit>(
        create: (context) => UserProfileCubit(
            userApiService: context.read<UserApiService>(),
            authCubit: context.read<AuthCubit>()),
      ),
      BlocProvider<UserInteractionCubit>(
        create: (context) {
          final userApiService = context.read<UserApiService>();
          final authApiService = context.read<AuthApiService>(); // Assuming AuthApiService is provided
      final authCubit = context.read<AuthCubit>();
          return UserInteractionCubit(userApiService: userApiService, authApiService: authApiService, authCubit: authCubit);
        }),
    ],
    child: UserProfilePage(userAnonymousId: userAnonymousId),
  );
 }

// Helper class for SliverPersistentHeader to make TabBar sticky
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Or AppBar color
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

extension StringExtension on String {
    String capitalizeFirstOfEach() => replaceAll(RegExp(r'_'), ' ').split(" ").map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(" ");
}