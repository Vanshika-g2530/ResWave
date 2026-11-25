import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/constants/app_colors.dart';
import '../../models/team_request.dart' hide ProjectModel;
import '../../models/project_models.dart';
import '../../models/group_model.dart';
import '../../services/api_client.dart';

class ProjectsScreen extends StatefulWidget {
  final int initialTabIndex;

  const ProjectsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ResWaveApiService _apiService = ResWaveApiService();

  List<TeamRequestModel> _teamCalls = [];
  List<dynamic> _myApplications = [];
  List<ProjectModel> _myProjects = [];
  List<GroupModel> _myGroups = [];
  List<dynamic> _recommendedGroups = [];
  List<GroupModel> _allGroups = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 4,
      initialIndex: widget.initialTabIndex.clamp(0, 3).toInt(),
      vsync: this,
    );

    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _apiService.getTeamRequests(),
        _apiService.getMyTeamApplications(),
        _apiService.getMyProjects(),
        _apiService.getMyGroups(),
        _apiService.getRecommendedGroups(),
        _apiService.getGroups(),
      ]);

      if (mounted) {
        setState(() {
          _teamCalls = futures[0] as List<TeamRequestModel>;
          _myApplications = futures[1];
          _myProjects = futures[2] as List<ProjectModel>;
          _myGroups = futures[3] as List<GroupModel>;
          _recommendedGroups = futures[4];
          _allGroups = futures[5] as List<GroupModel>;
        });
      }
    } catch (e) {
      debugPrint('Error loading projects data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================================================
  // CREATE TEAM REQUEST
  // =========================================================

  void _showCreateTeamRequestModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final domainController = TextEditingController();
    final skillsController = TextEditingController();

    int membersNeeded = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                const Text(
                  'Create Research Team Call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Project Title *',
                    hintText: 'e.g. Cognitive Load Analysis in Medical UIs',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Project Description *',
                    hintText:
                        'Explain your methodology, research gap, target conference...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Research Domain *',
                    hintText: 'e.g. hci, ai-nlp, cog-psych',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Must-Have Skills (comma-separated) *',
                    hintText: 'e.g. Python, Eye Tracking, Statistical R',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Collaborators Needed:',
                      style: TextStyle(fontSize: 14),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                          ),
                          onPressed: membersNeeded > 1
                              ? () {
                                  setModalState(
                                    () => membersNeeded--,
                                  );
                                }
                              : null,
                        ),
                        Text(
                          '$membersNeeded',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                          ),
                          onPressed: () {
                            setModalState(
                              () => membersNeeded++,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
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
                      if (titleController.text.trim().length < 5 ||
                          descController.text.trim().length < 20) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter a title (at least 5 characters) and description (at least 20 characters).',
                            ),
                          ),
                        );
                        return;
                      }

                      final skills = skillsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final payload = {
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'primaryDomain': domainController.text.trim().isNotEmpty
                            ? domainController.text.trim()
                            : 'hci',
                        'mustHaveSkills': skills,
                        'membersNeeded': membersNeeded,
                        'visibility': 'Discoverable',
                        'projectStage': 'Ideation',
                        'requiredRoles': <String>[],
                        'expectedCommitmentHours': 8,
                        'collaborationMode': 'Remote',
                      };

                      Navigator.pop(ctx);

                      try {
                        await _apiService.createTeamRequest(payload);
                        await _loadAllData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Post Team Call'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // APPLY TO TEAM + LOCAL PDF RESUME
  // =========================================================

  void _showApplyModal(TeamRequestModel call) {
    final messageController = TextEditingController();
    final skillsController = TextEditingController();
    final hoursController = TextEditingController();

    String? stagedResumeFileName;
    String? stagedResumePath;
    bool isUploadingResume = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                  'Apply: ${call.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  call.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  '1. Application Message & Contributions: *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe your interest and relevant research contributions...',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '2. Relevant Skills (comma-separated): *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: skillsController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Python, PyTorch, User Studies',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '3. Weekly Availability Commitment:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: hoursController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 8-10 hours / week',
                  ),
                ),
                const SizedBox(height: 14),

                // Resume Attachment Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.darkDivider,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: AppColors.brightTeal,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stagedResumeFileName ??
                                  'Attach Academic CV / Resume',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'PDF • Saved privately on this phone (max 25 MB)',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // CORRECTED FILE PICKER FOR VERSION 13.4.1
                      OutlinedButton(
                        onPressed: isUploadingResume
                            ? null
                            : () async {
                                setModalState(() {
                                  isUploadingResume = true;
                                });

                                try {
                                  final PlatformFile? picked =
                                      await FilePicker.pickFile(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                  );

                                  if (picked == null) {
                                    setModalState(() {
                                      isUploadingResume = false;
                                    });
                                    return;
                                  }

                                  final bytes = await picked.readAsBytes();

                                  if (bytes.length > 25 * 1024 * 1024) {
                                    throw Exception(
                                      'PDF must be 25 MB or smaller.',
                                    );
                                  }

                                  final appDirectory =
                                      await getApplicationDocumentsDirectory();

                                  final userId = _apiService.currentUser?.uid ??
                                      'local-user';

                                  final resumeDirectory = Directory(
                                    '${appDirectory.path}/ResWave/$userId/resumes',
                                  );

                                  await resumeDirectory.create(
                                    recursive: true,
                                  );

                                  final fileName =
                                      'resume_${DateTime.now().millisecondsSinceEpoch}.pdf';

                                  final savedFile = File(
                                    '${resumeDirectory.path}/$fileName',
                                  );

                                  await savedFile.writeAsBytes(
                                    bytes,
                                    flush: true,
                                  );

                                  setModalState(() {
                                    stagedResumeFileName = picked.name;
                                    stagedResumePath = savedFile.path;
                                    isUploadingResume = false;
                                  });
                                } catch (e) {
                                  setModalState(() {
                                    isUploadingResume = false;
                                  });

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not select resume: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          stagedResumeFileName == null
                              ? 'Select PDF'
                              : 'Change',
                        ),
                      ),

                      if (stagedResumePath != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'View selected resume',
                          icon: const Icon(
                            Icons.visibility,
                            color: AppColors.brightTeal,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LocalResumePdfViewer(
                                  filePath: stagedResumePath!,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                    ),
                    onPressed: () async {
                      if (messageController.text.trim().isEmpty) {
                        return;
                      }

                      Navigator.pop(ctx);

                      final skills = skillsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      try {
                        await _apiService.applyToTeam(
                          call.id,
                          message: messageController.text.trim(),
                          skills: skills,
                          answers: [
                            messageController.text.trim(),
                            hoursController.text.trim(),
                          ],
                          resumeFileName: stagedResumeFileName,
                          resumeStoragePath: stagedResumePath,
                          resumeUrl: stagedResumePath,
                        );

                        await _loadAllData();

                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Application submitted! Project owner notified.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CREATE GROUP
  // =========================================================

  void _showCreateGroupModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final domainController = TextEditingController();

    String membershipMode = 'Open';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                const Text(
                  'Create Research Community Group',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Group Title *',
                    hintText: 'e.g. Cross-Disciplinary XR Lab',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description & Focus *',
                    hintText:
                        'Describe purpose, reading topics, meeting cadence...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Domain *',
                    hintText: 'e.g. hci, ai-nlp',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: membershipMode,
                  decoration: const InputDecoration(
                    labelText: 'Membership Access',
                  ),
                  items: ['Open', 'Request to join', 'Invite only']
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setModalState(() {
                      membershipMode = v ?? membershipMode;
                    });
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                    ),
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        return;
                      }

                      final payload = {
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'primaryDomain': domainController.text.trim().isNotEmpty
                            ? domainController.text.trim()
                            : 'hci',
                        'topics': <String>[],
                        'purpose': descController.text.trim(),
                        'rules': '',
                        'membershipMode': membershipMode,
                        'visibility': 'Discoverable',
                      };

                      Navigator.pop(ctx);

                      try {
                        await _apiService.createGroup(payload);
                        await _loadAllData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Create Group'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MAIN BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams, Projects & Groups'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryTeal,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Team Calls'),
            Tab(text: 'Your Applications'),
            Tab(text: 'Workspaces'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTeamCallsTab(),
                _buildYourApplicationsTab(),
                _buildWorkspacesTab(),
                _buildGroupsTab(),
              ],
            ),
    );
  }

  // =========================================================
  // TEAM CALLS TAB
  // =========================================================

  Widget _buildTeamCallsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Open Research Collaborations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                  ),
                  onPressed: _showCreateTeamRequestModal,
                ),
              ],
            ),
          ),
          Expanded(
            child: _teamCalls.isEmpty
                ? const Center(
                    child: Text(
                      'No team calls posted yet. Create one above!',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: _teamCalls.length,
                    itemBuilder: (context, index) {
                      final call = _teamCalls[index];

                      final isOwner =
                          call.ownerId == _apiService.currentUser?.uid;

                      final isAlreadyApplied = _myApplications.any(
                        (a) => a['requestId'] == call.id,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      call.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkBackground,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${call.remainingCapacity} Slots Left',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.brightTeal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                call.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.darkTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: call.mustHaveSkills
                                    .map(
                                      (s) => Chip(
                                        label: Text(
                                          s,
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
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: isOwner
                                    ? OutlinedButton(
                                        onPressed: () {
                                          _showReviewApplicantsModal(call);
                                        },
                                        child: const Text(
                                          'Review Applicants',
                                        ),
                                      )
                                    : isAlreadyApplied
                                        ? const OutlinedButton(
                                            onPressed: null,
                                            child: Text('Applied'),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryTeal,
                                            ),
                                            onPressed: () {
                                              _showApplyModal(call);
                                            },
                                            child: const Text(
                                              'Apply for Role',
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

  // =========================================================
  // YOUR APPLICATIONS TAB
  // =========================================================

  Widget _buildYourApplicationsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: _myApplications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 54,
                    color: AppColors.darkTextMuted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No team applications submitted yet.',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _tabController.animateTo(0),
                    child: const Text('Browse Team Calls'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myApplications.length,
              itemBuilder: (context, index) {
                final app = _myApplications[index];

                final status = app['status'] ?? 'Pending';

                Color statusColor = AppColors.warning;

                if (status == 'Accepted') {
                  statusColor = AppColors.success;
                }

                if (status == 'Declined') {
                  statusColor = AppColors.error;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                app['projectTitle'] ?? 'Research Team',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (app['message'] != null)
                          Text(
                            'Message: ${app['message']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (app['skills'] != null &&
                            app['skills'] is List &&
                            (app['skills'] as List).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Skills Offered: ${(app['skills'] as List).map((e) => e.toString()).join(", ")}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                        if (app['resumeStoragePath'] is String &&
                            (app['resumeStoragePath'] as String).isNotEmpty &&
                            !((app['resumeStoragePath'] as String)
                                .startsWith('gs://')))
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () async {
                                final path =
                                    app['resumeStoragePath'].toString();

                                final fileExists = await File(path).exists();

                                if (!mounted) return;
                                if (!context.mounted) return;

                                if (fileExists) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => LocalResumePdfViewer(
                                        filePath: path,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'This resume is stored locally on the device where it was selected.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('View selected resume'),
                            ),
                          ),
                        if (app['resumeFileName'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attachment,
                                  size: 14,
                                  color: AppColors.brightTeal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Attached: ${app['resumeFileName']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.brightTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Applied: ${app['createdAt']?.toString().split("T")[0] ?? ""}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.darkTextMuted,
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

  // =========================================================
  // REVIEW APPLICANTS
  // =========================================================

  void _showReviewApplicantsModal(TeamRequestModel call) async {
    final apps = await _apiService.getTeamRequestApplications(call.id);

    if (!mounted) return;

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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applicants for "${call.title}"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: apps.isEmpty
                  ? const Center(
                      child: Text('No applications received yet.'),
                    )
                  : ListView.builder(
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        final a = apps[index];
                        final status = a['status'] ?? 'Pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      a['applicantName'] ?? 'Applicant',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      status,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.brightTeal,
                                      ),
                                    ),
                                  ],
                                ),
                                if (a['message'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${a['message']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                if (a['resumeFileName'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Resume: ${a['resumeFileName']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.brightTeal,
                                      ),
                                    ),
                                  ),
                                if (status == 'Pending') ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);

                                          await _apiService
                                              .decideTeamApplication(
                                            a['id'],
                                            'Declined',
                                          );

                                          await _loadAllData();
                                        },
                                        child: const Text(
                                          'Decline',
                                          style: TextStyle(
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryTeal,
                                        ),
                                        onPressed: () async {
                                          Navigator.pop(ctx);

                                          await _apiService
                                              .decideTeamApplication(
                                            a['id'],
                                            'Accepted',
                                          );

                                          await _loadAllData();
                                        },
                                        child: const Text('Accept Member'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
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

  // =========================================================
  // WORKSPACES TAB
  // =========================================================

  Widget _buildWorkspacesTab() {
    return _myProjects.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    size: 54,
                    color: AppColors.darkTextMuted,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'No Active Workspaces',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _myProjects.length,
            itemBuilder: (context, index) {
              final proj = _myProjects[index];

              return Card(
                child: ListTile(
                  title: Text(proj.title),
                  subtitle: Text(
                    '${proj.memberIds.length} Members • ${proj.status}',
                  ),
                ),
              );
            },
          );
  }

  // =========================================================
  // GROUPS TAB
  // =========================================================

  Widget _buildGroupsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Research Communities',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                onPressed: _showCreateGroupModal,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // My Groups
          const Text(
            'My Groups',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.brightTeal,
            ),
          ),
          const SizedBox(height: 8),

          if (_myGroups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'You have not joined any research groups yet.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            )
          else
            ..._myGroups.map(
              (g) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    g.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${g.memberCount} Members • ${g.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: () async {
                      await _apiService.leaveGroup(g.id);
                      await _loadAllData();
                    },
                    child: const Text('Leave'),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Recommended Groups
          if (_recommendedGroups.isNotEmpty) ...[
            const Text(
              'Recommended for Your Research',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.brightTeal,
              ),
            ),
            const SizedBox(height: 8),
            ..._recommendedGroups.map(
              (rec) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              rec['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
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
                              '${rec['memberCount']} Members',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.brightTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      if (rec['matchReasons'] != null &&
                          (rec['matchReasons'] as List).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '• ${(rec['matchReasons'] as List).join(" • ")}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.brightTeal,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                          ),
                          onPressed: () async {
                            await _apiService.joinGroup(rec['id']);
                            await _loadAllData();
                          },
                          child: const Text('Join Group'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Discover Groups
          const Text(
            'Discover Groups',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.brightTeal,
            ),
          ),
          const SizedBox(height: 8),

          ..._allGroups
              .where(
                (g) => !_myGroups.any((mg) => mg.id == g.id),
              )
              .map(
                (g) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      g.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${g.memberCount} Members • ${g.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                      ),
                      onPressed: () async {
                        await _apiService.joinGroup(g.id);
                        await _loadAllData();
                      },
                      child: Text(
                        g.membershipMode == 'Open' ? 'Join' : 'Request',
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ===========================================================
// LOCAL RESUME PDF VIEWER
// ===========================================================

class LocalResumePdfViewer extends StatefulWidget {
  final String filePath;

  const LocalResumePdfViewer({
    super.key,
    required this.filePath,
  });

  @override
  State<LocalResumePdfViewer> createState() => _LocalResumePdfViewerState();
}

class _LocalResumePdfViewerState extends State<LocalResumePdfViewer> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();

    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
      ),
      body: PdfViewPinch(
        controller: _controller,
      ),
    );
  }
}
