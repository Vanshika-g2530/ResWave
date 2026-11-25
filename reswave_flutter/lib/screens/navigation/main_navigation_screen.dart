import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../home/home_dashboard_screen.dart';
import '../discover/discover_screen.dart';
import '../network/network_screen.dart';
import '../projects/projects_screen.dart';
import '../profile/profile_screen.dart';
import '../research_hub/domain_finder_screen.dart';
import '../wellbeing/wellbeing_screen.dart';
import '../learning_hub/learning_hub_screen.dart';
import '../papers/paper_library_screen.dart';
import '../community/feed_screen.dart';
import '../messages/conversations_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../profile/interests_manager_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/push_notification_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserModel currentUser;

  const MainNavigationScreen({super.key, required this.currentUser});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    ResWavePushNotificationService.instance.markApplicationReady();
    _screens = [
      HomeDashboardScreen(user: widget.currentUser),
      const DiscoverScreen(),
      const NetworkScreen(),
      const ProjectsScreen(),
      ProfileScreen(user: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        widget.currentUser.isAdmin || widget.currentUser.role.contains('Admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ResWave',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ConversationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationCenterScreen()));
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.darkSurface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.deepTeal, AppColors.primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(widget.currentUser.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.currentUser.role,
                  style: const TextStyle(
                      color: AppColors.brightTeal, fontSize: 12)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.darkBackground,
                child: Text(
                  widget.currentUser.displayName.isNotEmpty
                      ? widget.currentUser.displayName[0]
                      : 'U',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: AppColors.brightTeal),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.compass_calibration_rounded,
                  color: AppColors.brightTeal),
              title: const Text('Research Domain Finder'),
              subtitle: const Text('7-question interest questionnaire',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DomainFinderScreen()));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.forum_rounded, color: AppColors.brightTeal),
              title: const Text('Academic Community Feed'),
              subtitle: const Text('Share research updates & questions',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FeedScreen()));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.school_rounded, color: AppColors.brightTeal),
              title: const Text('Research Learning Hub'),
              subtitle: const Text('Methodology & publishing guides',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LearningHubScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded,
                  color: AppColors.brightTeal),
              title: const Text('Personal Paper Library'),
              subtitle: const Text('DOI tracking and private reading notes',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PaperLibraryScreen()));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.spa_rounded, color: AppColors.brightTeal),
              title: const Text('Well-being & Peer Support'),
              subtitle: const Text('100% confidential mood check-ins',
                  style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            WellbeingScreen(user: widget.currentUser)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology_rounded,
                  color: AppColors.brightTeal),
              title: const Text('Manage Research Interests'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InterestsManagerScreen()));
              },
            ),
            if (isAdmin) ...[
              const Divider(color: AppColors.darkBorder),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.warning),
                title: const Text('Admin & Governance Console',
                    style: TextStyle(
                        color: AppColors.warning, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen()));
                },
              ),
            ],
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded), label: 'Discover'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded), label: 'Network'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group_work_rounded), label: 'Groups'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
