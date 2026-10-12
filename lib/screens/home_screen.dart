import 'package:flutter/material.dart';

const teal = Color(0xFF075E54);
const mint = Color(0xFFB9F3E9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final liked = <int>{};
  final posts = const [
    {
      'name': 'Dr. Mira Nair',
      'role': 'Assistant Professor · IIT Hyderabad',
      'initials': 'MN',
      'time': '2h',
      'text': 'We have been exploring inclusive ways to make online learning more accessible. What methods have worked well in your research or teaching?',
      'tag': 'Inclusive HCI',
      'likes': 42,
      'comments': 8,
    },
    {
      'name': 'Arjun Menon',
      'role': 'PhD Scholar · IIT Bombay',
      'initials': 'AM',
      'time': '5h',
      'text': 'Looking for collaborators interested in social computing and mixed-methods research. I would love to exchange ideas with researchers in this space.',
      'tag': 'Collaboration',
      'likes': 28,
      'comments': 12,
    },
    {
      'name': 'Ananya Sharma',
      'role': 'PhD Researcher · Computer Science / HCI',
      'initials': 'AS',
      'time': '1d',
      'text': 'A reminder for fellow researchers: asking for help is part of doing good research. Sharing resources and supporting each other makes academia better.',
      'tag': 'Research Life',
      'likes': 67,
      'comments': 14,
    },
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.waves_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ResWave',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: teal,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _message('Notifications will be connected later.'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                IconButton(
                  onPressed: () => _message('Search is available in Discover.'),
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2EAE6)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: mint,
                      child: Text(
                        'AS',
                        style: TextStyle(
                          color: teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _compose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8F6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'Share your research or thoughts…',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    _action(Icons.image_outlined, 'Media'),
                    _action(Icons.article_outlined, 'Paper'),
                    _action(Icons.help_outline, 'Ask'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Row(
              children: [
                Text(
                  'Your academic feed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Spacer(),
                Icon(Icons.tune, color: teal, size: 18),
                SizedBox(width: 5),
                Text(
                  'Relevant',
                  style: TextStyle(color: teal, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _post(i),
            childCount: posts.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    ),
  );
  Widget _action(IconData icon, String label) => Expanded(
    child: TextButton.icon(
      onPressed: _compose,
      icon: Icon(icon, color: teal, size: 18),
      label: Text(label, style: const TextStyle(color: teal, fontSize: 12)),
    ),
  );
  Widget _post(int i) {
    final p = posts[i];
    final isLiked = liked.contains(i);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: mint,
                child: Text(
                  p['initials'] as String,
                  style: const TextStyle(
                    color: teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      p['role'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      p['time'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    _message('More post options will be added later.'),
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p['text'] as String,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${(p['tag'] as String).replaceAll(' ', '')}',
              style: const TextStyle(
                color: teal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFF0F8B78), size: 15),
              const SizedBox(width: 5),
              Text(
                '${(p['likes'] as int) + (isLiked ? 1 : 0)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const Spacer(),
              Text(
                '${p['comments']} comments',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              _postButton(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                isLiked ? 'Liked' : 'Like',
                () => setState(() => isLiked ? liked.remove(i) : liked.add(i)),
              ),
              _postButton(
                Icons.mode_comment_outlined,
                'Comment',
                () => _message('Comments will be connected later.'),
              ),
              _postButton(
                Icons.repeat_rounded,
                'Repost',
                () => _message('Repost will be connected later.'),
              ),
              _postButton(
                Icons.share_outlined,
                'Share',
                () => _message('Share will be connected later.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _postButton(IconData icon, String label, VoidCallback onTap) =>
      Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Icon(icon, size: 18, color: teal),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  void _compose() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a post',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share a research update, question or idea…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _message(
                    'Post composer ready. Publishing will be connected later.',
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
