import 'package:empathy_hub_app/features/home/presentation/pages/home_page.dart'; // Your feed page
import 'package:empathy_hub_app/features/ai_chat/presentation/pages/ai_chat_page.dart'; // AI Chat Page Shell
import 'package:empathy_hub_app/features/chat/presentation/pages/chat_lobby_page.dart'; // Chat Lobby Page Shell
import 'package:flutter/material.dart';
import 'package:empathy_hub_app/features/navigation/presentation/widgets/app_drawer.dart'; // Import AppDrawer

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Key for the Scaffold
  int _selectedIndex = 0; // Default to the first tab (Feed)

  // List of pages to navigate to.
  // Make sure you have created basic shells for AIChatPage and ChatLobbyPage
  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(), // Index 0: Feed
    AIChatPage(), // Index 1: AI Chat (Shell)
    ChatLobbyPage(), // Index 2: Chat Lobby (Shell)
  ];

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
            IconButton(icon: const Icon(Icons.filter_list_alt), onPressed: () { /* TODO: Filter */ }),
          ]
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
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
}