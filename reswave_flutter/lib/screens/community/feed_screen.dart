import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/feed_models.dart';
import '../../services/api_client.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<FeedPostModel> _posts = [];
  bool _isLoading = true;
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Research update',
    'Question',
    'Paper share',
    'Project update',
    'General academic discussion',
  ];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getFeed(
        postType: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      if (mounted) setState(() => _posts = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading feed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReaction(FeedPostModel post) async {
    try {
      final reacted = await _apiService.reactToPost(post.id);
      setState(() {
        final idx = _posts.indexWhere((p) => p.id == post.id);
        if (idx != -1) {
          final current = _posts[idx];
          final newCount = reacted
              ? current.reactionCount + 1
              : (current.reactionCount > 0 ? current.reactionCount - 1 : 0);
          _posts[idx] = FeedPostModel(
            id: current.id,
            authorId: current.authorId,
            authorName: current.authorName,
            authorHeadline: current.authorHeadline,
            text: current.text,
            postType: current.postType,
            domainTags: current.domainTags,
            attachmentUrl: current.attachmentUrl,
            audience: current.audience,
            reactionCount: newCount,
            commentCount: current.commentCount,
            createdAt: current.createdAt,
          );
        }
      });
    } catch (_) {}
  }

  void _showCommentsSheet(FeedPostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) =>
          _CommentsSheetContent(post: post, apiService: _apiService),
    );
  }

  void _showCreatePostModal() {
    final textController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedType = 'Research update';
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
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
                  'Share with Academic Community',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Post Type'),
                  items: const [
                    'Research update',
                    'Question',
                    'Paper share',
                    'Project update',
                    'General academic discussion',
                  ]
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) => setSheetState(() {
                            selectedType = value ?? selectedType;
                          }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsController,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Domain Tags (comma-separated)',
                    hintText: 'e.g. NLP, HCI, Usability',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  enabled: !isSubmitting,
                  maxLength: 3000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Discussion Text (max 3000 chars)',
                    hintText:
                        'Share research findings, questions, or methodology reflections...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final postText = textController.text.trim();
                            if (postText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please enter your post before submitting.')),
                              );
                              return;
                            }

                            setSheetState(() => isSubmitting = true);
                            final tags = tagsController.text
                                .split(',')
                                .map((tag) => tag.trim())
                                .where((tag) => tag.isNotEmpty)
                                .toList();

                            try {
                              await _apiService.createFeedPost(
                                text: postText,
                                postType: selectedType,
                                domainTags: tags,
                              );

                              if (!mounted) return;
                              Navigator.of(sheetContext).pop();
                              await _loadFeed();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Post published successfully.')),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Could not publish post: $e')),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Post to Community'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      textController.dispose();
      tagsController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFeed,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryTeal,
        onPressed: _showCreatePostModal,
        child:
            const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // Category chips filter
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = (_selectedCategory ?? 'All') == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat,
                        style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : AppColors.darkTextSecondary)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryTeal,
                    backgroundColor: AppColors.darkSurface,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                      _loadFeed();
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadFeed,
                    child: _posts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No academic posts in this category yet. Be the first to share research updates with the community!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.darkTextSecondary),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              final p = _posts[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 14),
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
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    AppColors.primaryTeal,
                                                child: Text(
                                                  p.authorName.isNotEmpty
                                                      ? p.authorName[0]
                                                      : 'S',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(p.authorName,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14)),
                                                  Text(
                                                      p.authorHeadline ??
                                                          'Researcher',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .darkTextSecondary)),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.darkBackground,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: AppColors.darkBorder),
                                            ),
                                            child: Text(p.postType,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.brightTeal,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(p.text,
                                          style: const TextStyle(
                                              fontSize: 14, height: 1.4)),
                                      if (p.domainTags.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          children: p.domainTags
                                              .map((t) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .darkBackground,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text('#$t',
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color: AppColors
                                                                .darkTextMuted)),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton.icon(
                                            icon: const Icon(
                                                Icons.thumb_up_alt_outlined,
                                                size: 16),
                                            label: Text('${p.reactionCount}'),
                                            style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.brightTeal),
                                            onPressed: () => _handleReaction(p),
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(
                                                Icons
                                                    .chat_bubble_outline_rounded,
                                                size: 16),
                                            label: Text(
                                                '${p.commentCount} Comments'),
                                            style: TextButton.styleFrom(
                                                foregroundColor: AppColors
                                                    .darkTextSecondary),
                                            onPressed: () =>
                                                _showCommentsSheet(p),
                                          ),
                                        ],
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
      ),
    );
  }
}

class _CommentsSheetContent extends StatefulWidget {
  final FeedPostModel post;
  final ResWaveApiService apiService;

  const _CommentsSheetContent({required this.post, required this.apiService});

  @override
  State<_CommentsSheetContent> createState() => _CommentsSheetContentState();
}

class _CommentsSheetContentState extends State<_CommentsSheetContent> {
  final TextEditingController _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  String? _loadError;

  Future<void> _loadComments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final list = await widget.apiService.getPostComments(widget.post.id);
      if (mounted) setState(() => _comments = list);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final newComment =
          await widget.apiService.addPostComment(widget.post.id, text);
      if (!mounted) return;
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Academic Discussion',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_comments.length} comments',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.darkTextMuted)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Could not load comments: $_loadError',
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              TextButton(
                                  onPressed: _loadComments,
                                  child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _comments.isEmpty
                        ? const Center(
                            child: Text(
                                'No comments yet. Start the academic discussion.'))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final c = _comments[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppColors.darkBackground,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.authorName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.brightTeal)),
                                    const SizedBox(height: 4),
                                    Text(c.text,
                                        style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              left: 12,
              right: 12,
              top: 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              border: Border(top: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add to this research discussion...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                  onPressed: _isSubmitting ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
