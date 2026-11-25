import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/paper_item.dart';
import '../../services/api_client.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PaperLibraryScreen extends StatefulWidget {
  const PaperLibraryScreen({super.key});

  @override
  State<PaperLibraryScreen> createState() => _PaperLibraryScreenState();
}

class _PaperLibraryScreenState extends State<PaperLibraryScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<PaperItem> _papers = [];
  bool _isLoading = true;
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPapers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getMyPapers();
      if (mounted) setState(() => _papers = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddPaperDialog() {
    final titleController = TextEditingController();
    final authorsController = TextEditingController();
    final doiController = TextEditingController();
    final yearController = TextEditingController();
    final urlController = TextEditingController();
    final notesController = TextEditingController();
    String readingStatus = 'To Read';
    String? stagedPdfFileName;
    String? stagedStoragePath;
    bool isUploadingFile = false;

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
                const Text('Add Paper to Research Library',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'Papers and personal notes are private and encrypted to your account.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                      labelText: 'Paper Title *',
                      hintText: 'e.g. Attention Is All You Need'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorsController,
                  decoration: const InputDecoration(
                      labelText: 'Authors (comma-separated)',
                      hintText: 'e.g. Vaswani, Shazeer, Parmar'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: doiController,
                        decoration: const InputDecoration(
                            labelText: 'DOI (Optional)',
                            hintText: '10.1145/...'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Year', hintText: '2023'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                      labelText: 'ArXiv or Publication URL (HTTPS)',
                      hintText: 'https://arxiv.org/abs/...'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: readingStatus,
                  decoration:
                      const InputDecoration(labelText: 'Reading Status'),
                  items: ['To Read', 'Reading', 'Completed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => readingStatus = v ?? readingStatus),
                ),
                const SizedBox(height: 12),
                // PDF Attachment Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkDivider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf,
                          color: AppColors.brightTeal, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stagedPdfFileName ??
                                  'Attach Research PDF Document',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Max 25MB • Uploads to private Firebase Storage',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: isUploadingFile
                            ? null
                            : () async {
                                try {
                                  final files = await FilePicker.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                  );

                                  if (!context.mounted || files.isEmpty) {
                                    return;
                                  }

                                  final selectedFile = files.single;
                                  final selectedFileSize =
                                      await selectedFile.length();
                                  if (!context.mounted) return;

                                  if (selectedFileSize == null) {
                                    throw StateError(
                                        'Could not determine selected PDF size');
                                  }

                                  if (selectedFileSize > 25 * 1024 * 1024) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'PDF must be smaller than 25 MB'),
                                      ),
                                    );
                                    return;
                                  }

                                  final sourcePath = selectedFile.path;

                                  if (sourcePath == null) {
                                    throw Exception(
                                        'Could not access selected PDF');
                                  }

                                  setModalState(() => isUploadingFile = true);

                                  final uid = _apiService.currentUser?.uid ??
                                      'usr-local';

                                  final appDirectory =
                                      await getApplicationDocumentsDirectory();
                                  if (!context.mounted) return;

                                  final userDirectory = Directory(
                                    '${appDirectory.path}/ResWave/$uid/ResearchLibrary',
                                  );

                                  await userDirectory.create(recursive: true);
                                  if (!context.mounted) return;

                                  final fileName =
                                      '${DateTime.now().millisecondsSinceEpoch}_${selectedFile.name}';

                                  final savedFile = await File(sourcePath).copy(
                                    '${userDirectory.path}/$fileName',
                                  );
                                  if (!context.mounted) return;

                                  setModalState(() {
                                    stagedPdfFileName = selectedFile.name;
                                    stagedStoragePath = savedFile.path;
                                    isUploadingFile = false;
                                  });
                                } catch (e) {
                                  if (!context.mounted) return;
                                  setModalState(() => isUploadingFile = false);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('PDF selection failed: $e')),
                                  );
                                }
                              },
                        child: Text(stagedPdfFileName == null
                            ? 'Select PDF'
                            : 'Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Private Notes (Strictly Confidential)',
                    hintText:
                        'Key methodology takeaways, weaknesses, potential future work...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal),
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final paper = PaperItem(
                        id: 'paper-${DateTime.now().millisecondsSinceEpoch}',
                        userId: _apiService.currentUser?.uid ?? 'usr-local',
                        title: titleController.text.trim(),
                        authors: authorsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        doi: doiController.text.trim().isNotEmpty
                            ? doiController.text.trim()
                            : null,
                        year: int.tryParse(yearController.text),
                        url: stagedStoragePath ??
                            (urlController.text.trim().isNotEmpty
                                ? urlController.text.trim()
                                : null),
                        readingStatus: readingStatus,
                        privateNotes: notesController.text.trim().isNotEmpty
                            ? notesController.text.trim()
                            : null,
                      );
                      Navigator.pop(ctx);
                      await _apiService.addPaper(paper);
                      _loadPapers();
                    },
                    child: const Text('Save to Library'),
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
    var filtered = _papers;
    if (_statusFilter != 'All') {
      filtered = filtered
          .where((p) =>
              p.readingStatus.toLowerCase() == _statusFilter.toLowerCase())
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final q = _searchQuery.toLowerCase();
        return p.title.toLowerCase().contains(q) ||
            p.authors.any((a) => a.toLowerCase().contains(q)) ||
            (p.privateNotes?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Research Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddPaperDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search library by title, author, or private notes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children:
                  ['All', 'To Read', 'Reading', 'Completed'].map((status) {
                final isSel =
                    _statusFilter.toLowerCase() == status.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status, style: const TextStyle(fontSize: 12)),
                    selected: isSel,
                    selectedColor: AppColors.primaryTeal,
                    onSelected: (val) {
                      if (val) setState(() => _statusFilter = status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.library_books_outlined,
                                size: 54, color: AppColors.darkTextMuted),
                            const SizedBox(height: 12),
                            Text(
                              _papers.isEmpty
                                  ? 'No papers in your research library yet.'
                                  : 'No papers match your filters.',
                              style: const TextStyle(
                                  color: AppColors.darkTextSecondary),
                            ),
                            const SizedBox(height: 14),
                            if (_papers.isEmpty)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add First Paper / PDF'),
                                onPressed: _showAddPaperDialog,
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPapers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final paper = filtered[index];
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.brightTeal
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            paper.readingStatus,
                                            style: const TextStyle(
                                                color: AppColors.brightTeal,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18, color: AppColors.error),
                                          onPressed: () async {
                                            await _apiService
                                                .deletePaper(paper.id);
                                            _loadPapers();
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      paper.title,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${paper.authors.join(", ")}${paper.year != null ? " (${paper.year})" : ""}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.darkTextSecondary),
                                    ),
                                    if (paper.doi != null &&
                                        paper.doi!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text('DOI: ${paper.doi}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.darkTextMuted)),
                                      ),
                                    if (paper.privateNotes != null &&
                                        paper.privateNotes!.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.darkBackground,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.lock_outline,
                                                size: 14,
                                                color: AppColors.brightTeal),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                paper.privateNotes!,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (paper.url != null &&
                                        paper.url!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.open_in_new,
                                              size: 14),
                                          label: const Text('Open Paper / PDF'),
                                          onPressed: () async {
                                            final path = paper.url!;

                                            final file = File(path);

                                            if (await file.exists()) {
                                              await OpenFilex.open(path);
                                            } else {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'PDF file not found on this device.'),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
