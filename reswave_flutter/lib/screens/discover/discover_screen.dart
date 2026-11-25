import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/opportunity.dart';
import '../../services/api_client.dart';

String _discoverText(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;

  if (value is Iterable) {
    return value.map(_discoverText).where((e) => e.isNotEmpty).join(', ');
  }

  if (value is Map) {
    return value.values
        .map(_discoverText)
        .where((e) => e.isNotEmpty)
        .join(', ');
  }

  return value.toString();
}

List<String> _discoverList(dynamic value) {
  if (value == null) return <String>[];

  if (value is String) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  if (value is Iterable) {
    return value.map(_discoverText).where((e) => e.isNotEmpty).toList();
  }

  if (value is Map) {
    return value.values.map(_discoverText).where((e) => e.isNotEmpty).toList();
  }

  return <String>[_discoverText(value)];
}

class DiscoverScreen extends StatefulWidget {
  final int initialTabIndex;

  const DiscoverScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ResWaveApiService _apiService = ResWaveApiService();

  List<dynamic> _researchers = [];
  List<dynamic> _mentors = [];
  List<dynamic> _sentMentorRequests = [];
  List<OpportunityModel> _opportunities = [];

  bool _loadingResearchers = true;
  bool _loadingMentors = true;
  bool _loadingOpportunities = true;

  String? _errorResearchers;
  String? _errorMentors;
  String? _errorOpportunities;

  // Research Context for Mentor Matching
  final TextEditingController _researchTopicController =
      TextEditingController();

  final TextEditingController _neededExpertiseController =
      TextEditingController();

  final TextEditingController _searchMentorController = TextEditingController();

  bool _showContextFilters = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    _fetchResearchers();
    _fetchMentors();
    _fetchOpportunities();
    _fetchSentRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _researchTopicController.dispose();
    _neededExpertiseController.dispose();
    _searchMentorController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------
  // FETCH RESEARCHERS
  // ---------------------------------------------------------

  Future<void> _fetchResearchers() async {
    setState(() {
      _loadingResearchers = true;
      _errorResearchers = null;
    });

    try {
      final res = await _apiService.getResearcherMatches();

      if (mounted) {
        setState(() {
          _researchers = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorResearchers = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingResearchers = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // FETCH MENTORS
  // ---------------------------------------------------------

  Future<void> _fetchMentors() async {
    setState(() {
      _loadingMentors = true;
      _errorMentors = null;
    });

    try {
      final topics = _researchTopicController.text.trim();
      final help = _neededExpertiseController.text.trim();

      final res = await _apiService.getMentorMatches(
        topics: topics.isNotEmpty ? topics : null,
        helpType: help.isNotEmpty ? help : null,
      );

      if (mounted) {
        final query = _searchMentorController.text.trim().toLowerCase();

        if (query.isNotEmpty) {
          setState(() {
            _mentors = res.where((m) {
              final name = (m['displayName'] ?? '').toString().toLowerCase();

              final inst = (m['institution'] ?? '').toString().toLowerCase();

              final exp = _discoverList(
                m['expertise'] ?? m['expertiseTags'],
              ).join(' ').toLowerCase();

              return name.contains(query) ||
                  inst.contains(query) ||
                  exp.contains(query);
            }).toList();
          });
        } else {
          setState(() {
            _mentors = res;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMentors = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingMentors = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // FETCH SENT MENTOR REQUESTS
  // ---------------------------------------------------------

  Future<void> _fetchSentRequests() async {
    try {
      final res = await _apiService.getSentMentorRequests();

      if (mounted) {
        setState(() {
          _sentMentorRequests = res;
        });
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------
  // FETCH OPPORTUNITIES
  // ---------------------------------------------------------

  Future<void> _fetchOpportunities() async {
    setState(() {
      _loadingOpportunities = true;
      _errorOpportunities = null;
    });

    try {
      final res = await _apiService.getOpportunities();

      if (mounted) {
        setState(() {
          _opportunities = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorOpportunities = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingOpportunities = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // CONNECT DIALOG
  // ---------------------------------------------------------

  void _showConnectDialog(Map<String, dynamic> researcher) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Connect with ${researcher['displayName']}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${researcher['role']} • ${researcher['institution'] ?? ""}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Academic Introduction Note (Optional)',
                hintText: 'Mention shared research interests or papers...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                await _apiService.sendConnectionRequest(
                  researcher['userId'],
                  note: noteController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Connection request sent to ${researcher['displayName']}!',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                    ),
                  );
                }
              } finally {
                noteController.dispose();
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // MENTOR REQUEST DIALOG
  // ---------------------------------------------------------

  void _showMentorRequestDialog(Map<String, dynamic> mentor) {
    final availableHelpTypes = _discoverList(mentor['helpTypes']);

    String selectedHelp = availableHelpTypes.isNotEmpty
        ? availableHelpTypes.first
        : 'Methodology & Topic Selection';

    final contextController = TextEditingController();

    String selectedFormat = 'Remote';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) => Padding(
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
              Text(
                'Request Mentorship: ${mentor['displayName']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${mentor['institution'] ?? ""} • ${mentor['remainingCapacity']} Available Mentee Slots',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const Divider(height: 24),
              const Text(
                'What area do you need guidance on? *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedHelp,
                items: [
                  'Methodology & Topic Selection',
                  'Paper Writing & Rebuttals',
                  'Literature Review Guidance',
                  'Experimental Design',
                  'PhD Career & Workload',
                ]
                    .map(
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text(h),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  selectedHelp = v ?? selectedHelp;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Research Context & Objectives: *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: contextController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Describe what you are researching, current hurdles, and how this mentor\'s expertise connects...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                  ),
                  onPressed: () async {
                    if (contextController.text.trim().isEmpty) {
                      return;
                    }

                    Navigator.pop(ctx);

                    try {
                      await _apiService.sendMentorRequest(
                        mentorId: _discoverText(
                          mentor['mentorId'] ?? mentor['userId'],
                        ),
                        interestId: _discoverText(
                          mentor['interestId'],
                        ),
                        helpType: selectedHelp,
                        context: contextController.text.trim(),
                        format: selectedFormat,
                      );

                      await _fetchSentRequests();
                      await _fetchMentors();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Mentorship request sent to ${mentor['displayName']}!',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                          ),
                        );
                      }
                    } finally {
                      contextController.dispose();
                    }
                  },
                  child: const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover & Network'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryTeal,
          tabs: const [
            Tab(text: 'Researchers'),
            Tab(text: 'Mentors'),
            Tab(text: 'Opportunities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResearchersTab(),
          _buildMentorsTab(),
          _buildOpportunitiesTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // RESEARCHERS TAB
  // ---------------------------------------------------------

  Widget _buildResearchersTab() {
    if (_loadingResearchers) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorResearchers != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.darkTextMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not fetch matches',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchResearchers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_researchers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No matching researchers found yet. Add more research interests to your profile to improve discovery overlap.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkTextSecondary,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchResearchers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _researchers.length,
        itemBuilder: (context, index) {
          final r = _researchers[index];

          final tags = _discoverList(r['commonTopics']);
          final reasons = _discoverList(r['reasons']);

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
                      Text(
                        r['displayName'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brightTeal.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${r['score']}% Match',
                          style: const TextStyle(
                            color: AppColors.brightTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${r['role']} • ${r['institution'] ?? ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags
                        .map(
                          (t) => Chip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: AppColors.darkBackground,
                          ),
                        )
                        .toList(),
                  ),
                  if (reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...reasons.map(
                      (reason) => Text(
                        '• $reason',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.person_add_outlined,
                        size: 16,
                      ),
                      label: const Text('Connect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                      ),
                      onPressed: () => _showConnectDialog(r),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // MENTORS TAB
  // ---------------------------------------------------------

  Widget _buildMentorsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchMentors();
        await _fetchSentRequests();
      },
      child: Column(
        children: [
          // Research Context & Search header
          Container(
            color: AppColors.darkSurface,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchMentorController,
                        decoration: const InputDecoration(
                          hintText: 'Search mentors by name, domain, skills...',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _fetchMentors(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showContextFilters
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                        color: AppColors.brightTeal,
                      ),
                      onPressed: () {
                        setState(() {
                          _showContextFilters = !_showContextFilters;
                        });
                      },
                    ),
                  ],
                ),
                if (_showContextFilters) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _researchTopicController,
                    decoration: const InputDecoration(
                      labelText: 'What are you researching? (Topic/Domain)',
                      hintText: 'e.g. Human-Computer Interaction',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _neededExpertiseController,
                    decoration: const InputDecoration(
                      labelText: 'What additional expertise do you need?',
                      hintText: 'e.g. Statistical Modelling, NLP Evaluation',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                      ),
                      onPressed: _fetchMentors,
                      child: const Text('Apply Research Context'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sent Requests Banner
          if (_sentMentorRequests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              color: AppColors.darkBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_sentMentorRequests.length} Mentorship Request(s) Submitted',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brightTeal,
                    ),
                  ),
                  TextButton(
                    onPressed: _showSentRequestsModal,
                    child: const Text(
                      'View Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brightTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loadingMentors
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMentors != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: AppColors.darkTextMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Could not fetch mentors',
                              style: TextStyle(
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchMentors,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _mentors.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'No opted-in mentors with open slots found for your criteria. Check back soon.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _mentors.length,
                            itemBuilder: (context, index) {
                              final mentor = _mentors[index];

                              final expertise = _discoverList(
                                mentor['expertise'] ?? mentor['expertiseTags'],
                              );

                              final reasons = _discoverList(
                                mentor['reasons'],
                              );

                              final isAlreadyRequested =
                                  _sentMentorRequests.any(
                                (r) =>
                                    r['mentorId'] == mentor['mentorId'] &&
                                    r['status'] == 'Pending',
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            mentor['displayName'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.brightTeal
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${mentor['remainingCapacity']} Slots Open',
                                              style: const TextStyle(
                                                color: AppColors.brightTeal,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${mentor['institution'] ?? ""}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.darkTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: expertise
                                            .map(
                                              (e) => Chip(
                                                label: Text(
                                                  e,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    AppColors.darkBackground,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      if (reasons.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ...reasons.map(
                                          (r) => Text(
                                            '• $r',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color:
                                                  AppColors.darkTextSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: isAlreadyRequested
                                            ? const OutlinedButton(
                                                onPressed: null,
                                                child: Text(
                                                  'Request Pending',
                                                ),
                                              )
                                            : ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primaryTeal,
                                                ),
                                                onPressed: () =>
                                                    _showMentorRequestDialog(
                                                  mentor,
                                                ),
                                                child: const Text(
                                                  'Request Mentorship',
                                                ),
                                              ),
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

  // ---------------------------------------------------------
  // SENT MENTOR REQUESTS MODAL
  // ---------------------------------------------------------

  void _showSentRequestsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Sent Mentorship Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _sentMentorRequests.length,
                itemBuilder: (context, index) {
                  final req = _sentMentorRequests[index];
                  final status = req['status'] ?? 'Pending';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        'Mentor: ${req['mentorName'] ?? "Mentor"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Status: $status • Area: ${req['helpType']}',
                      ),
                      trailing: status == 'Pending'
                          ? TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);

                                await _apiService.withdrawMentorRequest(
                                  req['id'],
                                );

                                await _fetchSentRequests();
                                await _fetchMentors();
                              },
                              child: const Text(
                                'Withdraw',
                                style: TextStyle(
                                  color: AppColors.error,
                                ),
                              ),
                            )
                          : Text(
                              status,
                              style: TextStyle(
                                color: status == 'Accepted'
                                    ? AppColors.success
                                    : AppColors.darkTextMuted,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // OPPORTUNITIES TAB
  // ---------------------------------------------------------

  Widget _buildOpportunitiesTab() {
    if (_loadingOpportunities) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorOpportunities != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.darkTextMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not fetch opportunities',
              style: TextStyle(
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchOpportunities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_opportunities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No opportunities posted yet. Verified conferences and calls for papers appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkTextSecondary,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOpportunities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _opportunities.length,
        itemBuilder: (context, index) {
          final opp = _opportunities[index];

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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brightTeal.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          opp.type,
                          style: const TextStyle(
                            color: AppColors.brightTeal,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // FIXED: Correct OpportunityModel field
                      Text(
                        'Deadline: ${opp.submissionDeadline ?? "Not specified"}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opp.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // FIXED: Correct OpportunityModel fields
                  Text(
                    '${opp.organiser} • ${opp.tags.join(', ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    opp.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 14,
                      ),
                      label: const Text('Official Portal'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Opening portal: ${opp.officialSourceUrl}',
                            ),
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
    );
  }
}
