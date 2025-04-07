import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../providers/settings_provider.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'connection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    // Initialize connection provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  // Initialize the app
  Future<void> _initializeApp() async {
    setState(() {
      _initializing = true;
    });

    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    await connectionProvider.initialize();

    setState(() {
      _initializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initializing
          ? _buildLoadingScreen()
          : _buildMainContent(),
      bottomNavigationBar: _initializing
          ? null
          : _buildBottomNavBar(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing MCP Client...'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: const [
        ChatScreen(),
        ConnectionScreen(),
        SettingsScreen(),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.link),
          label: 'Connection',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}