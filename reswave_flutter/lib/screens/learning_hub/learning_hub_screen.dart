import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/learning_resource.dart';
import '../../services/api_client.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<LearningResource> _resources = [];
  bool _isLoading = true;
  String _selectedLevel = '';
  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getLearningResources(
        level: _selectedLevel.isNotEmpty ? _selectedLevel : null,
      );
      if (mounted) setState(() => _resources = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openResourceDetail(LearningResource r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(r.level, style: const TextStyle(color: AppColors.brightTeal, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Text('${r.durationMinutes} min read', style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
                ],
              ),
              const SizedBox(height: 10),
              Text(r.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(r.category, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
              const Divider(height: 24),
              const Text('Overview & Learning Objectives', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(r.summary, style: const TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 16),
              const Text('Curated Academic Guidance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(r.contentOrUrl, style: const TextStyle(fontSize: 13, height: 1.5)),
              ),
              const SizedBox(height: 16),
              Text('Source: ${r.sourceName} • Reviewed: ${r.reviewedDate}', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guide progress saved to personal tracker!')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Research Learning Hub')),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.darkSurface,
            child: Row(
              children: [
                _buildLevelChip('All', ''),
                const SizedBox(width: 6),
                _buildLevelChip('Beginner', 'Beginner'),
                const SizedBox(width: 6),
                _buildLevelChip('Intermediate', 'Intermediate'),
                const SizedBox(width: 6),
                _buildLevelChip('Advanced', 'Advanced'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _resources.isEmpty
                    ? const Center(child: Text('No learning resources found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _resources.length,
                        itemBuilder: (context, index) {
                          final r = _resources[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openResourceDetail(r),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryTeal.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(r.level, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brightTeal)),
                                        ),
                                        Text('${r.durationMinutes} min', style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(r.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(r.summary, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 10),
                                    Text('Source: ${r.sourceName}', style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted)),
                                  ],
                                ),
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

  Widget _buildLevelChip(String label, String value) {
    final selected = _selectedLevel == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      selectedColor: AppColors.primaryTeal,
      onSelected: (val) {
        setState(() => _selectedLevel = value);
        _loadResources();
      },
    );
  }
}
