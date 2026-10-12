import 'package:flutter/material.dart';

const teal = Color(0xFF075E54);
const mint = Color(0xFFB9F3E9);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Text(
              'My Profile',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2EAE6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: mint,
                      child: Text(
                        'AS',
                        style: TextStyle(
                          color: teal,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ananya Sharma',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'PhD Researcher · Computer Science / HCI',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'India',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'About',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'I study how people learn and collaborate with technology. I care about inclusive, community-led research.',
                  style: TextStyle(height: 1.45, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _toast(
                        context,
                        'Profile editing will be added later.',
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit profile'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _toast(
                        context,
                        'Profile sharing will be added later.',
                      ),
                      icon: const Icon(Icons.ios_share, size: 17),
                      label: const Text('Share profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: _Section(
            title: 'Research interests',
            icon: Icons.science_outlined,
            items: [
              'Accessibility',
              'Digital well-being',
              'HCI',
              'Qualitative research',
              'Prototyping',
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: _Section(
            title: 'Publications & projects',
            icon: Icons.article_outlined,
            items: [
              'Designing for belonging in online learning · CHI 2025',
              'Accessible Research Toolkit',
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: _Section(
            title: 'Communities',
            icon: Icons.groups_outlined,
            items: [
              'Women in HCI Research',
              'PhD Commons',
              'Responsible Computing India',
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: _Section(
            title: 'Collaboration preferences',
            icon: Icons.handshake_outlined,
            items: ['Open to collaboration', 'Looking for a mentor'],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    ),
  );
  static void _toast(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.items,
  });
  final String title;
  final IconData icon;
  final List<String> items;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(17),
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
            Icon(icon, color: teal, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, size: 6, color: teal),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
