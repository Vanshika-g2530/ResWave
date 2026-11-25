import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/domain_model.dart';
import '../../models/research_interest.dart';
import '../../services/api_client.dart';

class InterestsManagerScreen extends StatefulWidget {
  const InterestsManagerScreen({super.key});

  @override
  State<InterestsManagerScreen> createState() => _InterestsManagerScreenState();
}

class _InterestsManagerScreenState extends State<InterestsManagerScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<ResearchInterest> _interests = [];
  List<DomainModel> _availableDomains = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.getMyInterests(),
        _apiService.getDomains(),
      ]);
      if (mounted) {
        setState(() {
          _interests = futures[0] as List<ResearchInterest>;
          _availableDomains = futures[1] as List<DomainModel>;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddOrEditModal({ResearchInterest? existing}) {
    String selectedDomain = existing != null
        ? existing.domainId
        : (_availableDomains.isNotEmpty ? _availableDomains.first.id : 'hci');
    final subdomainController =
        TextEditingController(text: existing?.subdomainId ?? '');
    final topicsController =
        TextEditingController(text: existing?.topicTags.join(', ') ?? '');
    String status = existing?.status ?? 'Exploring';
    String proficiency = existing?.proficiency ?? 'Beginner';

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
                Text(
                  existing == null
                      ? 'Add Research Focus Area'
                      : 'Edit Research Focus Area',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Multi-domain: Manage your active exploration areas independently.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedDomain,
                  decoration: const InputDecoration(labelText: 'Research Domain'),
                  items: _availableDomains.isNotEmpty
                      ? _availableDomains
                          .map((d) => DropdownMenuItem(
                              value: d.id, child: Text(d.name)))
                          .toList()
                      : const [
                          DropdownMenuItem(value: 'hci', child: Text('HCI')),
                          DropdownMenuItem(
                              value: 'ai-nlp', child: Text('AI & NLP')),
                        ],
                  onChanged: existing == null
                      ? (v) => setModalState(
                          () => selectedDomain = v ?? selectedDomain)
                      : null, // Domain fixed once created
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subdomainController,
                  decoration: const InputDecoration(
                    labelText: 'Subdomain / Focus Topic',
                    hintText: 'e.g. Usability in Explainable AI',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicsController,
                  decoration: const InputDecoration(
                    labelText: 'Keywords (comma-separated)',
                    hintText: 'e.g. eye tracking, visual attention',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['Exploring', 'Actively Researching', 'Published']
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (v) => setModalState(() => status = v ?? status),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: proficiency,
                        decoration:
                            const InputDecoration(labelText: 'Proficiency'),
                        items: ['Beginner', 'Intermediate', 'Advanced']
                            .map((p) => DropdownMenuItem(
                                value: p, child: Text(p, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => proficiency = v ?? proficiency),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal),
                    onPressed: () async {
                      if (subdomainController.text.trim().isEmpty) return;
                      final tags = topicsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      final interest = ResearchInterest(
                        id: existing?.id ??
                            'int-${DateTime.now().millisecondsSinceEpoch}',
                        userId: _apiService.currentUser?.uid ?? 'usr-local',
                        domainId: selectedDomain,
                        subdomainId: subdomainController.text.trim(),
                        topicTags: tags,
                        proficiency: proficiency,
                        status: status,
                        goals: ['Learn', 'Publish'],
                      );
                      Navigator.pop(ctx);
                      await _apiService.addInterest(interest);
                      _loadAll();
                    },
                    child: Text(existing == null
                        ? 'Save Research Focus'
                        : 'Update Research Focus'),
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
        title: const Text('Manage Research Interests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddOrEditModal(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _interests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.psychology_outlined,
                          size: 54, color: AppColors.darkTextMuted),
                      const SizedBox(height: 12),
                      const Text('No research interests saved.',
                          style: TextStyle(color: AppColors.darkTextSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddOrEditModal(),
                        child: const Text('+ Add First Research Focus'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _interests.length,
                  itemBuilder: (context, index) {
                    final item = _interests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.domainId.toUpperCase()} • ${item.subdomainId}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.status,
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
                              children: item.topicTags
                                  .map((t) => Chip(
                                        label: Text(t,
                                            style: const TextStyle(
                                                fontSize: 11)),
                                        backgroundColor:
                                            AppColors.darkBackground,
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Proficiency: ${item.proficiency}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.darkTextMuted),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18,
                                          color: AppColors.brightTeal),
                                      onPressed: () =>
                                          _showAddOrEditModal(existing: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: AppColors.error),
                                      onPressed: () async {
                                        await _apiService
                                            .deleteInterest(item.id);
                                        _loadAll();
                                      },
                                    ),
                                  ],
                                ),
                              ],
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
