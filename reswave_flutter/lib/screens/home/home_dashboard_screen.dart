import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/research_interest.dart';
import '../../services/api_client.dart';
import '../research_hub/domain_finder_screen.dart';
import '../profile/interests_manager_screen.dart';
import '../learning_hub/learning_hub_screen.dart';
import '../papers/paper_library_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final UserModel user;

  const HomeDashboardScreen({super.key, required this.user});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<ResearchInterest> _interests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getMyInterests();
      if (mounted) setState(() => _interests = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Academic Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primaryTeal,
                              child: Text(
                                widget.user.displayName.isNotEmpty
                                    ? widget.user.displayName[0]
                                    : 'U',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user.displayName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkTextPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.user.role} • ${widget.user.institution ?? widget.user.country}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metrics Row
                    Row(
                      children: [
                        _buildMetricTile('Interests', '${_interests.length}',
                            Icons.psychology_rounded, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const InterestsManagerScreen()));
                        }),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                            'Learning', 'Guides', Icons.school_rounded, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LearningHubScreen()));
                        }),
                        const SizedBox(width: 8),
                        _buildMetricTile(
                            'Papers', 'Library', Icons.menu_book_rounded, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PaperLibraryScreen()));
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Multi-Domain Research Section (Section 3.6)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active Research Focus Areas',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkTextPrimary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const DomainFinderScreen()));
                          },
                          child: const Text('+ Explore',
                              style: TextStyle(color: AppColors.brightTeal)),
                        ),
                      ],
                    ),
                    const Text(
                      'ResWave supports multi-domain exploration without forcing a single primary identity.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.darkTextMuted),
                    ),
                    const SizedBox(height: 10),

                    if (_interests.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Icon(Icons.compass_calibration_outlined,
                                  size: 40, color: AppColors.darkTextMuted),
                              const SizedBox(height: 8),
                              const Text('No research areas saved yet.',
                                  style: TextStyle(
                                      color: AppColors.darkTextSecondary)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const DomainFinderScreen()),
                                  );
                                },
                                child: const Text('Take Domain Questionnaire'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._interests.map((i) => _buildInterestCard(i)),

                    const SizedBox(height: 20),

                    // Quick Well-Being Banner
                    const Card(
                      color: AppColors.darkSurfaceVariant,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('🧘 Well-Being & Peer Haven',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Spacer(),
                                Chip(
                                  label: Text('100% Private',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.brightTeal)),
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(color: AppColors.brightTeal),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Log private emotional reflections or access peer support and 24/7 crisis hotlines.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricTile(
      String label, String value, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
            child: Column(
              children: [
                Icon(icon, color: AppColors.brightTeal, size: 22),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.darkTextMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestCard(ResearchInterest interest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${interest.domainId.toUpperCase()} • ${interest.subdomainId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    interest.status,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brightTeal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: interest.topicTags
                  .map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.darkBackground,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
