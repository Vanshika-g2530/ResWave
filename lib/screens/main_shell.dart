import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    DiscoverScreen(),
    SimplePage(title: 'Groups', icon: Icons.groups_outlined),
    SimplePage(title: 'Messages', icon: Icons.chat_bubble_outline),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFD8F4EE),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          label: 'Groups',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class SimplePage extends StatelessWidget {
  const SimplePage({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: const Color(0xFF075E54)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This section will be built next.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}
