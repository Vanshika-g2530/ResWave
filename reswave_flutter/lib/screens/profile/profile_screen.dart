import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/network_models.dart';
import '../../models/mentor_models.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import 'interests_manager_screen.dart';
import '../network/network_screen.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  final ResWaveAuthService _authService = ResWaveAuthService.instance;
  late UserModel _currentUser;
  NetworkSummaryModel? _networkSummary;
  MentorProfileModel? _mentorProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final profFuture = _apiService.getMyProfile();
      final netFuture = _apiService.getNetworkSummary();
      final mentorFuture = _apiService.getMentorProfile();

      final results = await Future.wait([profFuture, netFuture, mentorFuture]);
      if (mounted) {
        setState(() {
          _currentUser = results[0] as UserModel;
          _networkSummary = results[1] as NetworkSummaryModel;
          _mentorProfile = results[2] as MentorProfileModel;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog() {
    final nameController =
        TextEditingController(text: _currentUser.displayName);
    final headlineController =
        TextEditingController(text: _currentUser.headline ?? '');
    final bioController = TextEditingController(text: _currentUser.bio ?? '');
    final institutionController =
        TextEditingController(text: _currentUser.institution ?? '');
    final deptController =
        TextEditingController(text: _currentUser.department ?? '');
    final countryController = TextEditingController(text: _currentUser.country);
    final cityController = TextEditingController(text: _currentUser.city ?? '');
    String selectedMode = _currentUser.preferredCollaborationMode;
    String selectedVisibility = _currentUser.visibility;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Academic Profile',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Display Name *')),
                const SizedBox(height: 12),
                TextField(
                    controller: headlineController,
                    decoration: const InputDecoration(
                        labelText: 'Academic Headline',
                        hintText: 'e.g. Associate Professor in HCI')),
                const SizedBox(height: 12),
                TextField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Research Biography',
                        hintText:
                            'Summary of current research investigations...')),
                const SizedBox(height: 12),
                TextField(
                    controller: institutionController,
                    decoration: const InputDecoration(
                        labelText: 'Institution / Organization')),
                const SizedBox(height: 12),
                TextField(
                    controller: deptController,
                    decoration: const InputDecoration(
                        labelText: 'Department / Faculty')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: countryController,
                            decoration:
                                const InputDecoration(labelText: 'Country'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                            controller: cityController,
                            decoration:
                                const InputDecoration(labelText: 'City'))),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMode,
                  decoration: const InputDecoration(
                      labelText: 'Preferred Collaboration Mode'),
                  items: ['Remote', 'In-person', 'Hybrid', 'No preference']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => selectedMode = v ?? selectedMode),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedVisibility,
                  decoration:
                      const InputDecoration(labelText: 'Profile Visibility'),
                  items: ['Public to members', 'Connections only', 'Private']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setSheetState(
                      () => selectedVisibility = v ?? selectedVisibility),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final updated = await _apiService.updateMyProfile({
                          'displayName': nameController.text.trim(),
                          'headline': headlineController.text.trim(),
                          'bio': bioController.text.trim(),
                          'institution': institutionController.text.trim(),
                          'department': deptController.text.trim(),
                          'country': countryController.text.trim(),
                          'city': cityController.text.trim(),
                          'preferredCollaborationMode': selectedMode,
                          'visibility': selectedVisibility,
                        });
                        setState(() => _currentUser = updated);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMentorSettingsDialog() {
    bool enabled = _mentorProfile?.mentorshipEnabled ?? false;
    final capacityController =
        TextEditingController(text: '${_mentorProfile?.maxCapacity ?? 3}');
    final expertiseController = TextEditingController(
        text: _mentorProfile?.expertiseTags.join(', ') ?? 'HCI, AI, Ethics');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mentor Opt-in Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open to Mentoring'),
                  subtitle: const Text(
                      'Explicit opt-in as mandated by Section 8',
                      style: TextStyle(fontSize: 11)),
                  value: enabled,
                  onChanged: (v) => setDialogState(() => enabled = v),
                ),
                if (enabled) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Max Active Mentees Capacity',
                        hintText: 'e.g. 3'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expertiseController,
                    decoration: const InputDecoration(
                        labelText: 'Expertise Topics (comma-separated)'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal),
              onPressed: () async {
                Navigator.pop(ctx);
                final tags = expertiseController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                final cap = int.tryParse(capacityController.text.trim()) ?? 3;
                try {
                  final updated = await _apiService.updateMentorProfile({
                    'mentorshipEnabled': enabled,
                    'maxCapacity': cap,
                    'expertiseTags': tags,
                    'availability': enabled ? 'Available' : 'Paused',
                  });
                  setState(() => _mentorProfile = updated);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Mentor settings saved!'),
                          backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of ResWave?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                await _authService.signOut();
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ResWaveAuthService.messageForError(
                          error,
                          operation: 'sign out',
                        ),
                      ),
                    ),
                  );
                }
                return;
              }
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
          'This action is irreversible. All your private mood entries, library notes, and interests will be permanently deleted per data protection policy.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteMyAccount();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Confirm Deletion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connsCount = _networkSummary?.connectionsCount ?? 0;
    final followersCount = _networkSummary?.followersCount ?? 0;
    final followingCount = _networkSummary?.followingCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primaryTeal,
                              child: Text(
                                _currentUser.displayName.isNotEmpty
                                    ? _currentUser.displayName[0]
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(_currentUser.displayName,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                                '${_currentUser.role} • ${_currentUser.institution ?? _currentUser.country}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.darkTextSecondary)),
                            if (_currentUser.headline != null &&
                                _currentUser.headline!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(_currentUser.headline!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.darkTextPrimary)),
                            ],
                            const SizedBox(height: 16),
                            // Network counters row
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const NetworkScreen()));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                    color: AppColors.darkBackground,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildCountStat(
                                        '$connsCount', 'Connections'),
                                    _buildCountStat(
                                        '$followersCount', 'Followers'),
                                    _buildCountStat(
                                        '$followingCount', 'Following'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Biography
                    if (_currentUser.bio != null &&
                        _currentUser.bio!.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('About & Research Focus',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.brightTeal)),
                              const SizedBox(height: 8),
                              Text(_currentUser.bio!,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    // Quick Action Tiles
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.psychology_rounded,
                                color: AppColors.brightTeal),
                            title: const Text('Manage Research Interests'),
                            subtitle: const Text(
                                'Add, edit, or archive multi-domain interests',
                                style: TextStyle(fontSize: 11)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const InterestsManagerScreen()));
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.school_rounded,
                                color: AppColors.brightTeal),
                            title: const Text('Mentor Status & Capacity'),
                            subtitle: Text(
                                _mentorProfile?.mentorshipEnabled == true
                                    ? 'Opted in (${_mentorProfile?.maxCapacity} max mentees)'
                                    : 'Not mentoring currently',
                                style: const TextStyle(fontSize: 11)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: _showMentorSettingsDialog,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.people_outline_rounded,
                                color: AppColors.brightTeal),
                            title: const Text('My Network Hub'),
                            subtitle: const Text(
                                'Connections, requests, and subscriptions',
                                style: TextStyle(fontSize: 11)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const NetworkScreen()));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Account actions
                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out'),
                      onPressed: _handleLogout,
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: AppColors.error, size: 18),
                      label: const Text('Delete Account',
                          style:
                              TextStyle(color: AppColors.error, fontSize: 12)),
                      onPressed: _handleDeleteAccount,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCountStat(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.brightTeal)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.darkTextSecondary)),
      ],
    );
  }
}
