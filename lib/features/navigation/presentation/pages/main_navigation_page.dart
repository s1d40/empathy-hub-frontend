import 'package:empathy_hub_app/features/home/presentation/pages/home_page.dart'; // Your feed page
import 'package:empathy_hub_app/features/ai_chat/presentation/pages/ai_chat_page.dart'; // AI Chat Page Shell
import 'package:empathy_hub_app/features/chat/presentation/pages/chat_list_page.dart'; // Import ChatListPage
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import flutter_bloc
import 'package:empathy_hub_app/features/feed/presentation/cubit/feed_cubit.dart'; // Import FeedCubit
import 'package:empathy_hub_app/core/services/post_api_service.dart'; // Import PostApiService
import 'package:empathy_hub_app/features/navigation/presentation/widgets/app_drawer.dart'; // Import AppDrawer

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Key for the Scaffold
  int _selectedIndex = 0; // Default to the first tab (Feed)

  static const List<String> _widgetTitles = <String>[
    'Feed',
    'AI Pal',
    'Chat',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the key to the Scaffold
      appBar: AppBar(
        title: Text(_widgetTitles[_selectedIndex]), // Dynamic title
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined), // Gear icon
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open drawer using the key
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {
              // TODO: Implement notifications functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications (Not implemented yet)')),
              );
            },
          ),
          // Only show search and filter on the Feed tab
          if (_selectedIndex == 0) ...[
            IconButton(icon: const Icon(Icons.search_outlined), onPressed: () { /* TODO: Search */ }),
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Refresh Feed',
              onPressed: () {
                context.read<FeedCubit>().refreshPosts();
              },
            ),
            IconButton(icon: const Icon(Icons.filter_list_alt), onPressed: () { /* TODO: Filter */ }),
          ]
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex), // Call the getter
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_alt), // Or Icons.smart_toy
            label: 'AI Pal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
      drawer: const AppDrawer(), // Add the AppDrawer
    );
  }

  // Define _widgetOptions as a getter to create BlocProviders dynamically
  List<Widget> get _widgetOptions {
    return <Widget>[
      const HomePage(), // HomePage will use the globally provided FeedCubit
      const AIChatPage(), // Index 1: AI Chat (Shell)
      const ChatListPage(), // Index 2: Now points to our actual Chat List Page
    ];
  }
}