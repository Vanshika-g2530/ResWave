import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'rep-01',
      'target': 'Feed Post #post-09',
      'reason': 'Spam / Commercial solicitation',
      'status': 'Under Review',
      'reporter': 'usr-alex-phd',
    },
    {
      'id': 'rep-02',
      'target': 'User Profile #usr-spam-02',
      'reason': 'Unverified credentials claim',
      'status': 'Resolved',
      'reporter': 'usr-prof-elena',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin & Governance Console'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brightTeal,
          labelColor: AppColors.brightTeal,
          unselectedLabelColor: AppColors.darkTextMuted,
          tabs: const [
            Tab(text: 'Moderation'),
            Tab(text: 'Taxonomy'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModerationTab(),
          _buildTaxonomyTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildModerationTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final r = _reports[index];
        final isUnderReview = r['status'] == 'Under Review';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r['target'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isUnderReview ? AppColors.warning.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(r['status'], style: TextStyle(color: isUnderReview ? AppColors.warning : AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Reason: ${r['reason']}', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                Text('Reported by: ${r['reporter']}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                if (isUnderReview) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => r['status'] = 'Dismissed');
                        },
                        child: const Text('Dismiss', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () {
                          setState(() => r['status'] = 'Resolved (Content Removed)');
                        },
                        child: const Text('Remove Content', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaxonomyTab() {
    final domains = [
      {'name': 'Human-Computer Interaction (HCI)', 'sub': '4 subdomains • 28 keywords'},
      {'name': 'Artificial Intelligence & NLP', 'sub': '5 subdomains • 36 keywords'},
      {'name': 'Cognitive Psychology & Neuroscience', 'sub': '4 subdomains • 22 keywords'},
      {'name': 'Environmental Science & Climate', 'sub': '4 subdomains • 18 keywords'},
      {'name': 'Bio-Informatics & Health', 'sub': '3 subdomains • 15 keywords'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: domains.length,
      itemBuilder: (context, index) {
        final d = domains[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(d['sub']!, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
            trailing: const Icon(Icons.edit_note_rounded, color: AppColors.brightTeal),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Taxonomy editor opened for ${d['name']}')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: const Text(
            '🔒 Privacy Compliance: Aggregated statistics strictly EXCLUDE all private mood entries, reflections, and private paper notes.',
            style: TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
          ),
        ),
        const SizedBox(height: 16),
        _buildMetricRow('Total Registered Scholars', '248'),
        _buildMetricRow('Active Interdisciplinary Projects', '34'),
        _buildMetricRow('Open Team Calls', '12'),
        _buildMetricRow('Published Learning Guides', '18'),
        _buildMetricRow('Curated Academic Opportunities', '9'),
        _buildMetricRow('Open Moderation Reports', '1'),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brightTeal)),
          ],
        ),
      ),
    );
  }
}
