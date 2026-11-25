import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/network_models.dart';
import '../../services/api_client.dart';
import '../messages/chat_screen.dart';

class NetworkScreen extends StatefulWidget {
  final int initialTabIndex;

  const NetworkScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResWaveApiService _apiService = ResWaveApiService();

  List<ConnectionModel> _connections = [];
  List<FollowerModel> _followers = [];
  List<FollowerModel> _following = [];
  List<ConnectionRequestModel> _sentRequests = [];
  List<ConnectionRequestModel> _receivedRequests = [];

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      initialIndex: widget.initialTabIndex.clamp(0, 4).toInt(),
      vsync: this,
    );
    _loadAllNetworkData();
  }

  Future<void> _loadAllNetworkData() async {
    setState(() => _isLoading = true);
    try {
      final summaryFuture = _apiService.getNetworkSummary();
      final connectionsFuture = _apiService.getConnections();
      final followersFuture = _apiService.getFollowers();
      final followingFuture = _apiService.getFollowing();
      final sentFuture = _apiService.getSentRequests();
      final receivedFuture = _apiService.getReceivedRequests();

      final results = await Future.wait([
        summaryFuture,
        connectionsFuture,
        followersFuture,
        followingFuture,
        sentFuture,
        receivedFuture,
      ]);

      if (mounted) {
        setState(() {
          _connections = results[1] as List<ConnectionModel>;
          _followers = results[2] as List<FollowerModel>;
          _following = results[3] as List<FollowerModel>;
          _sentRequests = results[4] as List<ConnectionRequestModel>;
          _receivedRequests = results[5] as List<ConnectionRequestModel>;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(String reqId) async {
    try {
      await _apiService.acceptConnectionRequest(reqId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connection accepted! Direct messaging unlocked.'),
            backgroundColor: AppColors.success),
      );
      _loadAllNetworkData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _declineRequest(String reqId) async {
    try {
      await _apiService.declineConnectionRequest(reqId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request declined.')));
      _loadAllNetworkData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _withdrawRequest(String reqId) async {
    try {
      await _apiService.withdrawConnectionRequest(reqId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request withdrawn.')));
      _loadAllNetworkData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _toggleFollow(String targetUid) async {
    try {
      final isNowFollowing = await _apiService.toggleFollow(targetUid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isNowFollowing
                ? 'Following researcher'
                : 'Unfollowed researcher')),
      );
      _loadAllNetworkData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Academic Network'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.brightTeal,
          labelColor: AppColors.brightTeal,
          unselectedLabelColor: AppColors.darkTextMuted,
          tabs: [
            Tab(text: 'Connections (${_connections.length})'),
            Tab(text: 'Received (${_receivedRequests.length})'),
            Tab(text: 'Sent (${_sentRequests.length})'),
            Tab(text: 'Followers (${_followers.length})'),
            Tab(text: 'Following (${_following.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllNetworkData,
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText:
                            'Search researchers, institutions, or roles...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildConnectionsTab(),
                        _buildReceivedTab(),
                        _buildSentTab(),
                        _buildFollowersTab(),
                        _buildFollowingTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionsTab() {
    final filtered = _connections
        .where((c) =>
            c.displayName.toLowerCase().contains(_searchQuery) ||
            (c.institution?.toLowerCase().contains(_searchQuery) ?? false) ||
            c.role.toLowerCase().contains(_searchQuery))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState('No connections yet',
          'Explore the Discover tab to connect with peers and mentors.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryTeal,
              child: Text(c.displayName.isNotEmpty ? c.displayName[0] : 'U',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            title: Text(c.displayName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('${c.role} • ${c.institution ?? c.country ?? ""}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary)),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
              label: const Text('Message', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationTitle: c.displayName,
                      participantRole: c.role,
                      targetUserId: c.userId,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceivedTab() {
    if (_receivedRequests.isEmpty) {
      return _buildEmptyState('No pending requests',
          'You do not have any incoming connection requests.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _receivedRequests.length,
      itemBuilder: (context, index) {
        final r = _receivedRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryTeal,
                      child: Text(
                          r.senderName.isNotEmpty ? r.senderName[0] : 'U',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.senderName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                              '${r.senderRole ?? ""} • ${r.senderInstitution ?? ""}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (r.note != null && r.note!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('"${r.note}"',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _declineRequest(r.id),
                      child: const Text('Decline'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal),
                      onPressed: () => _acceptRequest(r.id),
                      child: const Text('Accept Connection'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentTab() {
    if (_sentRequests.isEmpty) {
      return _buildEmptyState('No sent requests',
          'Sent connection requests awaiting response appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final r = _sentRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.darkSurfaceVariant,
              child: Text(r.receiverName.isNotEmpty ? r.receiverName[0] : 'U'),
            ),
            title: Text(r.receiverName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Pending acceptance • ${r.receiverInstitution ?? ""}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary)),
            trailing: TextButton(
              onPressed: () => _withdrawRequest(r.id),
              child: const Text('Withdraw',
                  style: TextStyle(color: AppColors.error)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowersTab() {
    if (_followers.isEmpty) {
      return _buildEmptyState('No followers yet',
          'Researchers who subscribe to your research updates will appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final f = _followers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryTeal,
              child: Text(f.displayName.isNotEmpty ? f.displayName[0] : 'U',
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(f.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${f.role} • ${f.institution ?? ""}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary)),
            trailing: OutlinedButton(
              onPressed: () => _toggleFollow(f.userId),
              child: Text(f.isFollowing ? 'Following' : 'Follow Back'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    if (_following.isEmpty) {
      return _buildEmptyState('Not following anyone yet',
          'Follow researchers in your field to see their public research updates.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final f = _following[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryTeal,
              child: Text(f.displayName.isNotEmpty ? f.displayName[0] : 'U',
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(f.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${f.role} • ${f.institution ?? ""}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary)),
            trailing: OutlinedButton(
              onPressed: () => _toggleFollow(f.userId),
              child: const Text('Following'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded,
                size: 56, color: AppColors.darkTextMuted),
            const SizedBox(height: 14),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkTextSecondary)),
          ],
        ),
      ),
    );
  }
}
