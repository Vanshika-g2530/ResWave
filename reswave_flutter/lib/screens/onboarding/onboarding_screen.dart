import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/research_interest.dart';
import '../../services/api_client.dart';
import '../navigation/main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final UserModel user;

  const OnboardingScreen({super.key, required this.user});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0 to 3 (4 steps total as per Section 4.2)
  final int _totalSteps = 4;
  final ResWaveApiService _apiService = ResWaveApiService();

  // Step 1: Account info (Pre-populated from user)
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  // Step 2: Academic Identity
  late String _selectedRole;
  final _institutionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _degreeController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  // Step 3: Research Interests (Multi-Domain + 'Still Exploring')
  final List<ResearchInterest> _stagedInterests = [];
  bool _stillExploring = false;
  String _selectedDomain = 'hci';
  final _subdomainController = TextEditingController(text: 'Cognitive Ergonomics');
  final _topicsController = TextEditingController(text: 'cognitive load, accessibility');
  final String _interestProficiency = 'Beginner';

  // Step 4: Goals & Collaboration
  final List<String> _selectedGoals = ['Explore new domains', 'Learn research methodology'];
  String _collabMode = 'Remote';
  String _availability = '5-10 hours/week';

  bool _isSaving = false;

  final List<String> _availableDomains = [
    'hci',
    'ai-nlp',
    'psych-cog',
    'ethics-fairness',
    'bio-informatics'
  ];

  final Map<String, String> _domainNames = {
    'hci': 'Human-Computer Interaction (HCI)',
    'ai-nlp': 'Natural Language Processing & AI',
    'psych-cog': 'Cognitive Psychology',
    'ethics-fairness': 'Ethics & Fairness in Computing',
    'bio-informatics': 'Bioinformatics & Computational Biology',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.role.isNotEmpty ? widget.user.role : 'Student (UG/PG)';
    _institutionController.text = widget.user.institution ?? '';
    _departmentController.text = widget.user.department ?? '';
    _countryController.text = widget.user.country.isNotEmpty ? widget.user.country : 'United States';
    _cityController.text = widget.user.city ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _institutionController.dispose();
    _departmentController.dispose();
    _degreeController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _subdomainController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  void _addInterest() {
    if (_subdomainController.text.trim().isEmpty) return;
    setState(() {
      _stagedInterests.add(ResearchInterest(
        id: 'int-stage-${DateTime.now().millisecondsSinceEpoch}',
        userId: widget.user.uid,
        domainId: _selectedDomain,
        subdomainId: _subdomainController.text.trim(),
        topicTags: _topicsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        proficiency: _interestProficiency,
        status: 'Exploring',
        goals: _selectedGoals,
      ));
      _subdomainController.clear();
      _topicsController.clear();
    });
  }

  Future<void> _completeOnboarding({bool isPartial = false}) async {
    setState(() => _isSaving = true);
    try {
      // 1. Update academic profile
      final updatedUser = await _apiService.updateMyProfile({
        'displayName': _nameController.text.trim(),
        'role': _selectedRole,
        'institution': _institutionController.text.trim().isNotEmpty ? _institutionController.text.trim() : null,
        'department': _departmentController.text.trim().isNotEmpty ? _departmentController.text.trim() : null,
        'country': _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : 'Global',
        'city': _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        'preferredCollaborationMode': _collabMode,
      });

      // 2. Persist staged research interests
      if (_stillExploring && _stagedInterests.isEmpty) {
        await _apiService.addInterest(ResearchInterest(
          id: 'int-exploring',
          userId: widget.user.uid,
          domainId: 'hci',
          subdomainId: 'Interdisciplinary Exploration',
          topicTags: ['open exploration', 'foundational literature'],
          proficiency: 'Beginner',
          status: 'Exploring',
          goals: _selectedGoals,
        ));
      } else {
        for (final interest in _stagedInterests) {
          await _apiService.addInterest(interest);
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainNavigationScreen(currentUser: updatedUser)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving onboarding: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Academic Journey Setup'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _completeOnboarding(isPartial: true),
            child: const Text('Save & Later', style: TextStyle(color: AppColors.brightTeal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps: ${_stepTitle(_currentStep)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brightTeal),
                      ),
                      Text(
                        '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppColors.darkSurface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brightTeal),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),
            // Bottom Action Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(top: BorderSide(color: AppColors.darkBorder)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => setState(() => _currentStep--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_currentStep < _totalSteps - 1) {
                                setState(() => _currentStep++);
                              } else {
                                _completeOnboarding();
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Account Verification';
      case 1:
        return 'Academic Identity';
      case 2:
        return 'Research Interests';
      case 3:
        return 'Goals & Collaboration';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Account();
      case 1:
        return _buildStep2AcademicIdentity();
      case 2:
        return _buildStep3ResearchInterests();
      case 3:
        return _buildStep4GoalsCollab();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Account
  Widget _buildStep1Account() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirm Your Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Verify your basic account details and platform terms of service.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _emailController,
          readOnly: true,
          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined), helperText: 'Firebase authenticated email'),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AppColors.brightTeal, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text('ResWave Terms & Research Integrity Charter v3.0 accepted.', style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: Academic Identity
  Widget _buildStep2AcademicIdentity() {
    final roles = [
      'Student (UG/PG)',
      'PhD Scholar',
      'Professor / Faculty',
      'Researcher',
      'Independent Researcher',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Academic Affiliation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Tell peers where you are researching or studying. Affiliation is optional for independent scholars.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          decoration: const InputDecoration(labelText: 'Academic Role *', prefixIcon: Icon(Icons.school_outlined)),
          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedRole = v);
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _institutionController,
          decoration: const InputDecoration(labelText: 'Institution / University', hintText: 'e.g. Carnegie Mellon University or Independent', prefixIcon: Icon(Icons.account_balance_outlined)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _departmentController,
          decoration: const InputDecoration(labelText: 'Department / Faculty', hintText: 'e.g. Department of Computer Science', prefixIcon: Icon(Icons.domain_outlined)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country *', prefixIcon: Icon(Icons.public_outlined)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Research Interests (Section 3.6 - Multi-domain support)
  Widget _buildStep3ResearchInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Research Interests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Add one or more active research areas. You can pursue multiple domains independently.', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _stillExploring,
          contentPadding: EdgeInsets.zero,
          title: const Text('I am still exploring research fields', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('We will suggest introductory resources and domain quizzes.', style: TextStyle(fontSize: 12)),
          onChanged: (v) => setState(() => _stillExploring = v ?? false),
        ),
        if (!_stillExploring) ...[
          const Divider(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _selectedDomain,
            decoration: const InputDecoration(labelText: 'Select Broad Domain'),
            items: _availableDomains.map((d) => DropdownMenuItem(value: d, child: Text(_domainNames[d] ?? d))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedDomain = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subdomainController,
            decoration: const InputDecoration(labelText: 'Subdomain / Focus Area', hintText: 'e.g. Cognitive Ergonomics'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicsController,
            decoration: const InputDecoration(labelText: 'Topic Tags (comma-separated)', hintText: 'e.g. usability, interfaces, accessibility'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add This Area'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
              onPressed: _addInterest,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_stagedInterests.isNotEmpty) ...[
          const Text('Your Staged Research Areas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brightTeal)),
          const SizedBox(height: 8),
          ..._stagedInterests.map((interest) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(interest.subdomainId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(interest.topicTags.join(', '), style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      onPressed: () => setState(() => _stagedInterests.remove(interest)),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  // Step 4: Goals & Collaboration
  Widget _buildStep4GoalsCollab() {
    final allGoals = [
      'Explore new domains',
      'Learn research methodology',
      'Find a research mentor',
      'Find teammates for paper / project',
      'Publish academic paper',
      'Connect with domain scholars',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Goals & Collaboration Mode', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('What are you looking to achieve on ResWave?', style: TextStyle(color: AppColors.darkTextSecondary)),
        const SizedBox(height: 16),
        const Text('Research Goals (select all that apply):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allGoals.map((g) {
            final isSelected = _selectedGoals.contains(g);
            return FilterChip(
              label: Text(g, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.darkTextSecondary)),
              selected: isSelected,
              selectedColor: AppColors.primaryTeal,
              backgroundColor: AppColors.darkSurface,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedGoals.add(g);
                  } else {
                    _selectedGoals.remove(g);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Preferred Collaboration Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _collabMode,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.laptop_chromebook_outlined)),
          items: ['Remote', 'In-person', 'Hybrid', 'No preference'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _collabMode = v);
          },
        ),
        const SizedBox(height: 16),
        const Text('Weekly Availability:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _availability,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.access_time_outlined)),
          items: ['1-5 hours/week', '5-10 hours/week', '10-20 hours/week', '20+ hours/week', 'Flexible']
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _availability = v);
          },
        ),
      ],
    );
  }
}
