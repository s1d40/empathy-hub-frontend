import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/auth/presentation/widgets/auth_gate.dart'; // Import the separated AuthGate
import 'package:empathy_hub_app/core/services/auth_api_service.dart';
import 'package:empathy_hub_app/core/services/post_api_service.dart';
import 'package:empathy_hub_app/core/services/user_api_service.dart';
import 'package:empathy_hub_app/core/services/comment_api_service.dart';
import 'package:empathy_hub_app/features/settings/presentation/cubit/data_erasure_cubit.dart';
import 'package:empathy_hub_app/core/services/chat_api_service.dart'; // Import ChatApiService
import 'package:empathy_hub_app/core/services/report_api_service.dart'; // Import ReportApiService
import 'package:empathy_hub_app/core/services/general_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http; // Import http package
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:empathy_hub_app/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:empathy_hub_app/features/chat/presentation/cubit/chat_room_cubit/chat_room_cubit.dart';
import 'package:empathy_hub_app/features/chat/presentation/cubit/chat_initiation_cubit/chat_initiation_cubit.dart'; // Import ChatInitiationCubit
import 'package:empathy_hub_app/features/user_profile/presentation/cubit/user_interaction_lists_cubit.dart'; // Import UserInteractionListsCubit
import 'package:empathy_hub_app/features/user_profile/presentation/cubit/user_interaction_cubit.dart'; // Import UserInteractionCubit
import 'package:empathy_hub_app/features/report/presentation/cubit/report_cubit.dart'; // Import ReportCubit


Future<void> main() async { // Make main async
  // Ensure Flutter bindings are initialized, especially if you do async work before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // --- DEVELOPMENT ONLY: Clear SharedPreferences on app start ---
  // TODO: Remove this or make it conditional for release builds!
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  print("DEV_MODE: SharedPreferences cleared for fresh start.");
  // --- END DEVELOPMENT ONLY ---

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create instances of your API services
    // It's good practice to share a single http.Client instance if possible
    final httpClient = http.Client(); 
    final authApiService = AuthApiService(client: httpClient);
    final postApiService = PostApiService(client: httpClient);
    final userApiService = UserApiService(client: httpClient);
    final commentApiService = CommentApiService(client: httpClient);
    final generalApiService = GeneralApiService(client: httpClient);
    final chatApiService = ChatApiService(client: httpClient); // Create ChatApiService instance
    final reportApiService = ReportApiService(client: httpClient); // Create ReportApiService instance

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthApiService>.value(value: authApiService),
        RepositoryProvider<PostApiService>.value(value: postApiService),
        RepositoryProvider<UserApiService>.value(value: userApiService),
        RepositoryProvider<CommentApiService>.value(value: commentApiService),
        RepositoryProvider<GeneralApiService>.value(value: generalApiService),
        RepositoryProvider<ChatApiService>.value(value: chatApiService), // Provide ChatApiService
        RepositoryProvider<ReportApiService>.value(value: reportApiService), // Provide ReportApiService
        // If you want to dispose the client when the app closes, you might handle it differently
        // or provide it as a value and manage its lifecycle if necessary.
        // For simplicity here, we're just creating it.
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              context.read<AuthApiService>(), // Read the service provided above
            ),
          ),
          BlocProvider<FeedCubit>(
            create: (context) => FeedCubit(
              postApiService: context.read<PostApiService>(),
              authCubit: context.read<AuthCubit>(), // FeedCubit needs AuthCubit
            ),
          ),
          BlocProvider<ReportCubit>( // Add ReportCubit here
            create: (context) => ReportCubit(
              reportApiService: context.read<ReportApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<DataErasureCubit>( // Add DataErasureCubit here
            create: (context) => DataErasureCubit(
              authApiService: context.read<AuthApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<ChatInitiationCubit>( // Use ChatInitiationCubit
            create: (context) => ChatInitiationCubit(
              chatApiService: context.read<ChatApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<UserInteractionCubit>( // Add UserInteractionCubit here
            create: (context) => UserInteractionCubit(
              userApiService: context.read<UserApiService>(),
              authApiService: context.read<AuthApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
          BlocProvider<UserInteractionListsCubit>( // Add UserInteractionListsCubit here
            create: (context) => UserInteractionListsCubit(
              authApiService: context.read<AuthApiService>(),
              userApiService: context.read<UserApiService>(),
              authCubit: context.read<AuthCubit>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Empathy Hub',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthGate(),
        ),
    ));
  }
}