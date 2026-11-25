import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/domain_model.dart';
import '../../models/research_interest.dart';
import '../../services/api_client.dart';

class DomainFinderScreen extends StatefulWidget {
  const DomainFinderScreen({super.key});

  @override
  State<DomainFinderScreen> createState() => _DomainFinderScreenState();
}

class _DomainFinderScreenState extends State<DomainFinderScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();

  final List<String> _selectedSubjects = [];
  final List<String> _selectedProblems = [];
  final List<String> _selectedWorkStyles = [];
  final List<String> _selectedSkills = [];
  final List<String> _selectedGoals = [];

  final TextEditingController _topicController = TextEditingController();

  String _selectedExperience = 'None';

  List<DomainRecommendationResult> _recommendations = [];
  bool _isLoading = false;

  final List<String> _subjectOptions = [
    'computing',
    'mathematics',
    'psychology',
    'design',
    'biology',
    'environment',
    'social sciences',
    'medicine',
  ];

  final List<String> _problemOptions = [
    'human behaviour',
    'technology',
    'data/patterns',
    'design/experience',
    'climate',
    'health',
    'society',
  ];

  final List<String> _workStyleOptions = [
    'building prototypes',
    'analysing data',
    'interviews/surveys',
    'experiments',
    'designing experiences',
    'fieldwork',
  ];

  final List<String> _skillOptions = [
    'programming',
    'statistics',
    'design',
    'data analysis',
    'observation/interviews',
    'writing',
  ];

  final List<String> _goalOptions = [
    'explore',
    'solve practical problem',
    'publish',
    'prepare higher studies',
    'build portfolio',
  ];

  // Calculate domain recommendations
  Future<void> _calculateRecommendations() async {
    setState(() {
      _isLoading = true;
      _recommendations = [];
    });

    final payload = {
      'subjects': _selectedSubjects,
      'problems': _selectedProblems,
      'workStyles': _selectedWorkStyles,
      'skills': _selectedSkills,
      'goals': _selectedGoals,
      'experience': _selectedExperience,
      'topicInMind': _topicController.text.trim(),
    };

    try {
      final results = await _apiService.getDomainRecommendations(payload);

      if (!mounted) return;

      setState(() {
        _recommendations = results;
        _isLoading = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No domain recommendations found. Try different answers.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Save selected domain as research interest
  Future<void> _saveInterest(DomainRecommendationResult domain) async {
    final newInterest = ResearchInterest(
      id: 'int-${DateTime.now().millisecondsSinceEpoch}',
      userId: _apiService.currentUser?.uid ?? 'usr-local',
      domainId: domain.domainId,
      subdomainId: domain.sampleTopics.isNotEmpty
          ? domain.sampleTopics.first
          : 'General',
      topicTags: domain.sampleTopics.take(3).toList(),
      proficiency: 'Beginner',
      status: 'Exploring',
      skills: domain.requiredSkills.take(3).toList(),
      methods: ['Literature-based'],
      goals: ['Learn', 'Explore'],
    );

    try {
      await _apiService.addInterest(newInterest);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${domain.name} as an active research interest!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving interest: $e')),
      );
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Domain Finder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Explore Research Domains',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkTextPrimary,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Answer the questions below to discover research domains '
              'that match your interests, skills and goals.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkTextSecondary,
              ),
            ),

            const SizedBox(height: 20),

            // 1. Subjects
            _buildMultiSelectSection(
              '1. Which subjects interest you? (30%)',
              _subjectOptions,
              _selectedSubjects,
            ),

            // 2. Problems
            _buildMultiSelectSection(
              '2. Which problem types motivate you? (25%)',
              _problemOptions,
              _selectedProblems,
            ),

            // 3. Work styles
            _buildMultiSelectSection(
              '3. What kind of work would you enjoy? (20%)',
              _workStyleOptions,
              _selectedWorkStyles,
            ),

            // 4. Skills
            _buildMultiSelectSection(
              '4. Skills you have or want to develop? (15%)',
              _skillOptions,
              _selectedSkills,
            ),

            // 5. Goals
            _buildMultiSelectSection(
              '5. What is your research goal? (10%)',
              _goalOptions,
              _selectedGoals,
            ),

            // 6. Experience
            const Text(
              '6. What is your research experience?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.darkTextPrimary,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _selectedExperience,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'None',
                  child: Text('No experience'),
                ),
                DropdownMenuItem(
                  value: 'Beginner',
                  child: Text('Beginner'),
                ),
                DropdownMenuItem(
                  value: 'Intermediate',
                  child: Text('Intermediate'),
                ),
                DropdownMenuItem(
                  value: 'Advanced',
                  child: Text('Advanced'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedExperience = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // 7. Topic in mind
            TextField(
              controller: _topicController,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: '7. Any topic already in mind? (Optional)',
                hintText: 'e.g. Cognitive load in AI interfaces...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Calculate button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                onPressed: _isLoading ? null : _calculateRecommendations,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Calculate Domain Recommendations',
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Recommendation results
            if (_recommendations.isNotEmpty) ...[
              const Text(
                'Recommended Domains',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore your domain matches, understand why they '
                'were recommended and discover where to start.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextMuted,
                ),
              ),
              const SizedBox(height: 12),
              ..._recommendations.map(
                (rec) => _buildResultCard(rec),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Multi-select questionnaire section
  Widget _buildMultiSelectSection(
    String title,
    List<String> options,
    List<String> selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final isChecked = selected.contains(opt);

            return FilterChip(
              label: Text(
                opt[0].toUpperCase() + opt.substring(1),
                style: const TextStyle(fontSize: 11),
              ),
              selected: isChecked,
              selectedColor: AppColors.primaryTeal.withValues(alpha: 0.3),
              checkmarkColor: AppColors.brightTeal,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    selected.add(opt);
                  } else {
                    selected.remove(opt);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // Recommendation result card
  Widget _buildResultCard(
    DomainRecommendationResult result,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Domain name and fit score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    result.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: result.fitBand == 'Strong'
                        ? AppColors.brightTeal.withValues(alpha: 0.2)
                        : AppColors.primaryTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.brightTeal,
                    ),
                  ),
                  child: Text(
                    '${result.fitBand} (${result.score.toInt()}%)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brightTeal,
                    ),
                  ),
                ),
              ],
            ),

            // Sub-fields
            if (result.sampleTopics.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Sub-fields:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                result.sampleTopics.join(', '),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],

            // Why recommended
            const SizedBox(height: 10),

            const Text(
              'Why this appeared:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: AppColors.darkTextMuted,
              ),
            ),

            ...result.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(
                  left: 6,
                  top: 3,
                ),
                child: Text(
                  '• $reason',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ),

            // Skills to develop
            if (result.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Skills to develop:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                result.requiredSkills.join(', '),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],

            // Beginner resources
            if (result.beginnerResources.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Beginner Resources:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              ...result.beginnerResources.map(
                (resource) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontSize: 11),
                      ),
                      Expanded(
                        child: Text(
                          resource,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Example research questions
            if (result.sampleQuestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Example Research Questions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              ...result.sampleQuestions.take(3).map(
                    (question) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontSize: 11),
                          ),
                          Expanded(
                            child: Text(
                              question,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],

            // Research methods
            if (result.commonMethods.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Common Research Methods:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                result.commonMethods.join(', '),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],

            // Related groups
            if (result.relatedGroups.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Related Research Groups:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              ...result.relatedGroups.map(
                (group) => Text(
                  '• $group',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Save interest button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.bookmark_add_outlined,
                  size: 16,
                ),
                label: const Text('Save as Interest'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                onPressed: () => _saveInterest(result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
