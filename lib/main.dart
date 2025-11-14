import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/core/services/auth_api_service.dart';
import 'package:anonymous_hubs/core/services/notification_api_service.dart';
import 'package:anonymous_hubs/core/services/chat_api_service.dart';
import 'package:anonymous_hubs/core/services/post_api_service.dart';
import 'package:anonymous_hubs/core/services/comment_api_service.dart'; // Import CommentApiService
import 'package:anonymous_hubs/core/services/user_api_service.dart';
import 'package:anonymous_hubs/core/services/report_api_service.dart'; // Import ReportApiService
import 'package:anonymous_hubs/features/notification/presentation/cubit/notification_cubit/notification_cubit.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_list_cubit/chat_list_cubit.dart';
import 'package:anonymous_hubs/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_initiation_cubit/chat_initiation_cubit.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_request_cubit/chat_request_cubit.dart';
import 'package:anonymous_hubs/features/settings/presentation/cubit/data_erasure_cubit.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/cubit/user_interaction_lists_cubit.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/cubit/user_interaction_cubit.dart';
import 'package:anonymous_hubs/features/report/presentation/cubit/report_cubit.dart'; // Import ReportCubit
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'app.dart';

void main() {
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthApiService>(
          create: (context) => AuthApiService(
            client: http.Client(),
          ),
        ),
        RepositoryProvider<NotificationApiService>(
          create: (context) => NotificationApiService(
            client: http.Client(),
          ),
        ),
        RepositoryProvider<ChatApiService>(
          create: (context) => ChatApiService(
            client: http.Client(),
          ),
        ),
        RepositoryProvider<PostApiService>(
          create: (context) => PostApiService(
            client: http.Client(),
          ),
        ),
        RepositoryProvider<CommentApiService>( // Provide CommentApiService
          create: (context) => CommentApiService(
            client: http.Client(),
          ),
        ),
        RepositoryProvider<UserApiService>(
          create: (context) => UserApiService(
            client: http.Client(),
          ),
        ),
        RepositoryProvider<ReportApiService>( // Provide ReportApiService
          create: (context) => ReportApiService(
            client: http.Client(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              context.read<AuthApiService>(),
            ),
          ),
          BlocProvider<NotificationCubit>(
            create: (context) => NotificationCubit(
              notificationApiService: context.read<NotificationApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<ChatListCubit>(
            create: (context) => ChatListCubit(
              chatApiService: context.read<ChatApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<FeedCubit>(
            create: (context) => FeedCubit(
              authCubit: context.read<AuthCubit>(),
              postApiService: context.read<PostApiService>(),
            ),
          ),
          BlocProvider<ChatInitiationCubit>(
            create: (context) => ChatInitiationCubit(
              chatApiService: context.read<ChatApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<ChatRequestCubit>(
            create: (context) => ChatRequestCubit(
              chatApiService: context.read<ChatApiService>(),
              authCubit: context.read<AuthCubit>(),
              notificationCubit: context.read<NotificationCubit>(),
            ),
          ),
          BlocProvider<DataErasureCubit>(
            create: (context) => DataErasureCubit(
              authApiService: context.read<AuthApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<UserInteractionListsCubit>(
            create: (context) => UserInteractionListsCubit(
              authApiService: context.read<AuthApiService>(),
              userApiService: context.read<UserApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<UserInteractionCubit>(
            create: (context) => UserInteractionCubit(
              userApiService: context.read<UserApiService>(),
              authApiService: context.read<AuthApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<ReportCubit>(
            create: (context) => ReportCubit(
              reportApiService: context.read<ReportApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
        ],
        child: const AnonymousHubsApp(),
      ),
    ),
  );
}