import 'package:flutter/material.dart';

const teal = Color(0xFF075E54);
const mint = Color(0xFFB9F3E9);

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final search = TextEditingController();
  final filters = <String>{};
  String? need;
  final needs = const [
    ('Research guidance', Icons.science_outlined),
    ('Mentorship', Icons.handshake_outlined),
    ('Collaboration', Icons.groups_2_outlined),
    ('Peer support', Icons.favorite_border),
    ('Career guidance', Icons.trending_up),
    ('Funding & opportunities', Icons.currency_rupee),
  ];
  final people = const [
    {
      'name': 'Dr. Mira Nair',
      'role': 'Assistant Professor · IIT Hyderabad',
      'initials': 'MN',
      'area': 'Inclusive HCI',
      'skills': 'Qualitative methods · Accessibility',
      'stage': 'Faculty',
      'mentor': true,
      'collab': true,
    },
    {
      'name': 'Arjun Menon',
      'role': 'PhD Scholar · IIT Bombay',
      'initials': 'AM',
      'area': 'Social Computing',
      'skills': 'Mixed methods · Prototyping',
      'stage': 'PhD Scholar',
      'mentor': false,
      'collab': true,
    },
    {
      'name': 'Ananya Sharma',
      'role': 'PhD Researcher · Computer Science',
      'initials': 'AS',
      'area': 'Digital Well-being',
      'skills': 'HCI · User research',
      'stage': 'PhD Scholar',
      'mentor': true,
      'collab': true,
    },
    {
      'name': 'Kabir Rao',
      'role': 'Research Fellow · IISc Bengaluru',
      'initials': 'KR',
      'area': 'AI for Education',
      'skills': 'Machine learning · Evaluation',
      'stage': 'Research Fellow',
      'mentor': true,
      'collab': false,
    },
  ];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.toLowerCase().trim();
    final results = people.where((p) {
      final match =
          q.isEmpty ||
          '${p['name']} ${p['role']} ${p['area']} ${p['skills']}'
              .toLowerCase()
              .contains(q);
      final stage = filters
          .where(
            (f) => ['PhD Scholar', 'Faculty', 'Research Fellow'].contains(f),
          )
          .toList();
      final stageMatch = stage.isEmpty || stage.contains(p['stage']);
      final mentorMatch =
          !filters.contains('Open to mentorship') || p['mentor'] == true;
      final collabMatch =
          !filters.contains('Open to collaboration') || p['collab'] == true;
      final needMatch =
          need == null ||
          need == 'Peer support' ||
          need == 'Funding & opportunities' ||
          (need == 'Mentorship' && p['mentor'] == true) ||
          (need == 'Collaboration' && p['collab'] == true) ||
          (need == 'Research guidance' && p['area'] != null) ||
          (need == 'Career guidance' &&
              (p['mentor'] == true || p['stage'] == 'Faculty'));
      return match && stageMatch && mentorMatch && collabMatch && needMatch;
    }).toList();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Discover',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find people, ideas and support for your research.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Name, topic, skill or institution',
                  prefixIcon: const Icon(Icons.search, color: teal),
                  suffixIcon: IconButton(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.tune, color: teal),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDDE7E2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDDE7E2)),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip(
                    'All',
                    filters.isEmpty,
                    () => setState(() => filters.clear()),
                  ),
                  _chip(
                    'PhD Scholar',
                    filters.contains('PhD Scholar'),
                    () => _toggle('PhD Scholar'),
                  ),
                  _chip(
                    'Faculty',
                    filters.contains('Faculty'),
                    () => _toggle('Faculty'),
                  ),
                  _chip(
                    'Open to mentorship',
                    filters.contains('Open to mentorship'),
                    () => _toggle('Open to mentorship'),
                  ),
                  _chip(
                    'Open to collaboration',
                    filters.contains('Open to collaboration'),
                    () => _toggle('Open to collaboration'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [teal, Color(0xFF0F8B78)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.waves_rounded, color: mint),
                        SizedBox(width: 8),
                        Text(
                          'RESWAVE SUPPORT COMPASS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'What do you need help with today?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Start with your need to explore relevant people and communities.',
                      style: TextStyle(
                        color: Color(0xFFE1F4EF),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: needs
                          .map(
                            (n) => _needChip(
                              n.$1,
                              n.$2,
                              need == n.$1,
                              () => setState(
                                () => need = need == n.$1 ? null : n.$1,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (need != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Suggestions for: $need',
                          style: const TextStyle(
                            color: mint,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Researchers for you',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${results.length} found',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (results.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text(
                    'No matches yet. Try another search or clear a filter.',
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _person(results[i]),
                childCount: results.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  void _toggle(String f) =>
      setState(() => filters.contains(f) ? filters.remove(f) : filters.add(f));
  Widget _chip(String label, bool selected, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => tap(),
      selectedColor: mint,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFDDE7E2)),
      labelStyle: TextStyle(
        color: selected ? teal : Colors.black87,
        fontSize: 11,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
  Widget _needChip(
    String label,
    IconData icon,
    bool selected,
    VoidCallback tap,
  ) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? mint : Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? mint : Colors.white.withOpacity(.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: selected ? teal : Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? teal : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _person(Map<String, Object> p) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
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
                  const SizedBox(height: 3),
                  Text(
                    p['role'] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () =>
                  _toast('Connect request will be wired to the backend later.'),
              icon: const Icon(Icons.person_add_alt_1, color: teal),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          p['area'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: teal,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          p['skills'] as String,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (p['mentor'] == true) const _Badge('Open to mentorship'),
            if (p['collab'] == true) const _Badge('Open to collaboration'),
          ],
        ),
        const Divider(height: 22),
        Row(
          children: [
            TextButton(
              onPressed: () =>
                  _toast('Profile screen will be connected later.'),
              child: const Text('View profile'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _toast('Messaging will be connected later.'),
              child: const Text('Message'),
            ),
          ],
        ),
      ],
    ),
  );
  void _toast(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter researchers',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                ...[
                  'PhD Scholar',
                  'Faculty',
                  'Research Fellow',
                  'Open to mentorship',
                  'Open to collaboration',
                ].map(
                  (f) => CheckboxListTile(
                    value: filters.contains(f),
                    activeColor: teal,
                    contentPadding: EdgeInsets.zero,
                    title: Text(f),
                    onChanged: (v) {
                      setState(
                        () => v == true ? filters.add(f) : filters.remove(f),
                      );
                      refresh(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Apply filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF8F4),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: teal,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
