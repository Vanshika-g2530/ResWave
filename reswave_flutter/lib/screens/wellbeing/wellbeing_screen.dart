import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/mood_entry.dart';
import '../../services/api_client.dart';

class WellbeingScreen extends StatefulWidget {
  final UserModel user;

  const WellbeingScreen({super.key, required this.user});

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResWaveApiService _apiService = ResWaveApiService();

  List<MoodEntry> _moods = [];
  List<dynamic> _peerPosts = [];
  List<dynamic> _professionalResources = [];

  bool _isLoadingMoods = true;
  bool _isLoadingPosts = true;
  bool _isLoadingProfessionals = true;

  final TextEditingController _searchProfController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMoods();
    _loadPeerPosts();
    _loadProfessionalResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchProfController.dispose();
    super.dispose();
  }

  Future<void> _loadMoods() async {
    setState(() => _isLoadingMoods = true);
    try {
      final list = await _apiService.getMyMoods();
      if (mounted) setState(() => _moods = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMoods = false);
    }
  }

  Future<void> _loadPeerPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final list = await _apiService.getSupportPosts();
      if (mounted) setState(() => _peerPosts = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _loadProfessionalResources({String? query}) async {
    setState(() => _isLoadingProfessionals = true);
    try {
      final list = await _apiService.getProfessionalSupport(query: query);
      if (mounted) setState(() => _professionalResources = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingProfessionals = false);
    }
  }

  void _openMoodDialog() {
    String selectedMood = 'Calm';
    int intensity = 3;
    final factors = <String>[];
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: const Text('Private Mood Check-in',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your mood reflections are strictly confidential and visible only to you.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 14),
                const Text('How are you feeling?',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedMood,
                  decoration:
                      const InputDecoration(labelText: 'Primary Feeling'),
                  items: [
                    'Calm',
                    'Good',
                    'Motivated',
                    'Okay',
                    'Stressed',
                    'Overwhelmed',
                    'Low',
                    'Anxious'
                  ]
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedMood = v ?? selectedMood),
                ),
                const SizedBox(height: 12),
                Text('Intensity (1-5): $intensity',
                    style: const TextStyle(fontSize: 13)),
                Slider(
                  value: intensity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: AppColors.primaryTeal,
                  onChanged: (v) => setDialogState(() => intensity = v.toInt()),
                ),
                const SizedBox(height: 10),
                const Text('Key Factors:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    'Deadline',
                    'Paper Rejection',
                    'Advisor Meeting',
                    'Experiment Block',
                    'Workload',
                    'Progress'
                  ].map((factor) {
                    final isSel = factors.contains(factor);
                    return FilterChip(
                      label: Text(factor, style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      selectedColor:
                          AppColors.primaryTeal.withValues(alpha: 0.3),
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            factors.add(factor);
                          } else {
                            factors.remove(factor);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Private Reflection Note (Optional)',
                    hintText: 'What went well? What caused friction today?',
                  ),
                ),
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
                final entry = MoodEntry(
                  id: 'mood-${DateTime.now().millisecondsSinceEpoch}',
                  userId: widget.user.uid,
                  mood: selectedMood,
                  intensity: intensity,
                  factors: factors,
                  privateNote: noteController.text.trim().isNotEmpty
                      ? noteController.text.trim()
                      : null,
                  createdAt: DateTime.now().toIso8601String(),
                );
                Navigator.pop(ctx);
                await _apiService.saveMood(entry);
                _loadMoods();
              },
              child: const Text('Save Reflection'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSupportPostModal() {
    final textController = TextEditingController();
    String category = 'PhD Life';
    bool hideIdentity = true;
    bool safetyAcknowledged = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                const Text('Share with Peer Support Community',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'A safe space to discuss research workload, setbacks, and academic resilience.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    'PhD Life',
                    'Paper Rejection & Resilience',
                    'Work-Life Balance',
                    'Advisor Dynamics',
                    'Writing & Focus Block'
                  ]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Share your experience (avoid posting private personal/medical information)...',
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Post Anonymously to Members',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'Your name and profile link will be hidden from other scholars.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.darkTextSecondary)),
                  value: hideIdentity,
                  activeColor: AppColors.primaryTeal,
                  onChanged: (v) =>
                      setModalState(() => hideIdentity = v ?? true),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mandatory Safety Acknowledgement *',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning)),
                  subtitle: const Text(
                    'I acknowledge that peer support is for mutual encouragement and is NOT professional clinical therapy or crisis medical care.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.darkTextSecondary),
                  ),
                  value: safetyAcknowledged,
                  activeColor: AppColors.primaryTeal,
                  onChanged: (v) =>
                      setModalState(() => safetyAcknowledged = v ?? false),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal),
                    onPressed: safetyAcknowledged
                        ? () async {
                            if (textController.text.trim().isEmpty) return;
                            Navigator.pop(ctx);
                            try {
                              await _apiService.createSupportPost(
                                category: category,
                                text: textController.text.trim(),
                                hideIdentity: hideIdentity,
                              );
                              if (!mounted) return;
                              _loadPeerPosts();
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text('Support post shared with peers.'),
                                      backgroundColor: AppColors.success),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                        : null,
                    child: const Text('Share with Peers'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Well-Being & Support'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryTeal,
          tabs: const [
            Tab(text: 'My Mood (Private)'),
            Tab(text: 'Peer Support'),
            Tab(text: 'Professional Support'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Private Mood Check-in Tab
          _buildMoodTab(),

          // 2. Peer Support Community Tab
          _buildPeerSupportTab(),

          // 3. Professional Support Directory Tab (Section 4.3)
          _buildProfessionalSupportTab(),
        ],
      ),
    );
  }

  Widget _buildMoodTab() {
    return RefreshIndicator(
      onRefresh: _loadMoods,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mood & Resilience Reflection',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Strictly confidential • Never shared with mentors',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.darkTextSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
                  onPressed: _openMoodDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingMoods
                ? const Center(child: CircularProgressIndicator())
                : _moods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.self_improvement_rounded,
                                size: 54, color: AppColors.darkTextMuted),
                            const SizedBox(height: 12),
                            const Text('No mood check-ins recorded yet.',
                                style: TextStyle(
                                    color: AppColors.darkTextSecondary)),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _openMoodDialog,
                              child: const Text('Record First Check-in'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _moods.length,
                        itemBuilder: (context, index) {
                          final m = _moods[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryTeal
                                    .withValues(alpha: 0.2),
                                child: Text('${m.intensity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brightTeal)),
                              ),
                              title: Text(m.mood,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (m.factors.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                          'Factors: ${m.factors.join(', ')}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors
                                                  .darkTextSecondary)),
                                    ),
                                  if (m.privateNote != null &&
                                      m.privateNote!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('Note: ${m.privateNote}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic)),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.error),
                                onPressed: () async {
                                  await _apiService.deleteMood(m.id);
                                  _loadMoods();
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerSupportTab() {
    return RefreshIndicator(
      onRefresh: _loadPeerPosts,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Academic Peer Discussions',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.post_add_rounded, size: 16),
                  label: const Text('New Post'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
                  onPressed: _showCreateSupportPostModal,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingPosts
                ? const Center(child: CircularProgressIndicator())
                : _peerPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.forum_outlined,
                                size: 54, color: AppColors.darkTextMuted),
                            const SizedBox(height: 12),
                            const Text('No peer support posts yet.',
                                style: TextStyle(
                                    color: AppColors.darkTextSecondary)),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _showCreateSupportPostModal,
                              child: const Text('Share First Post'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _peerPosts.length,
                        itemBuilder: (context, index) {
                          final p = _peerPosts[index];
                          final author = p['authorDisplayName'] ??
                              (p['hideIdentity'] == true
                                  ? 'Anonymous Scholar'
                                  : (p['authorName'] ?? 'Scholar'));
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(author,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.darkBackground,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                            p['category'] ?? 'Academic Life',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.brightTeal)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(p['text'] ?? '',
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${p['likesCount'] ?? 0} Support Reactions',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors
                                                  .darkTextSecondary)),
                                      Text('${p['repliesCount'] ?? 0} Replies',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.brightTeal)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalSupportTab() {
    return Column(
      children: [
        // Non-clinical disclaimer banner (Section 4.3 requirement)
        Container(
          width: double.infinity,
          color: AppColors.darkSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.brightTeal, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notice: ResWave is an academic networking platform and is NOT a clinical, diagnostic, or emergency crisis service.',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.darkTextSecondary),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchProfController,
            decoration: InputDecoration(
              hintText: 'Search verified counsellors & specialists...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchProfController.clear();
                  _loadProfessionalResources();
                },
              ),
            ),
            onSubmitted: (val) => _loadProfessionalResources(query: val.trim()),
          ),
        ),
        Expanded(
          child: _isLoadingProfessionals
              ? const Center(child: CircularProgressIndicator())
              : _professionalResources.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined,
                                size: 54, color: AppColors.darkTextMuted),
                            SizedBox(height: 12),
                            Text(
                              'No verified professional resources matched your search.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.darkTextSecondary),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Only administrator-verified licensed professionals appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProfessionalResources,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _professionalResources.length,
                        itemBuilder: (context, index) {
                          final item = _professionalResources[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(item['name'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.success
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('Verified',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.success,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['category']} • ${item['institutionOrOrganization']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.brightTeal),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qualifications: ${item['qualifications']}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.darkTextMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item['description'] ?? '',
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Availability: ${item['availabilityNote']}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.darkTextSecondary),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.open_in_new,
                                          size: 14),
                                      label: const Text('View Official Portal'),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Opening: ${item['contactUrlOrEmail']}'),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
