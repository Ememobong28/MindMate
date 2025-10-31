import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import '../services/buddy_store.dart';
import 'home_screen.dart';
import 'predict_screen.dart';
import 'insights_screen.dart';
import 'commitments_screen.dart';
import 'profile_screen.dart';

class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});
  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  static const brand = Color(0xFF6D28D9);
  final _emailCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _store = BuddyStore.instance;

  @override
  void initState() {
    super.initState();
    _store.start();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    try {
      await _store.connectByEmail(email);
      _emailCtrl.clear();
      _snack('Buddy connected!');
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      current: AppPage.buddy,
      onGoDashboard: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      ),
      onGoCheckIn: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PredictScreen()),
      ),
      onGoInsights: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InsightsScreen()),
      ),
      onGoCommitments: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CommitmentsScreen()),
      ),
      onGoProfile: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      onGoBuddy: () {}, // already here
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accountability Buddy 💜',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3B0764),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Connect with a peer for mutual support and motivation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),

                // Connect card
                _Glass(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connect with Your Buddy',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'buddy@university.edu',
                                ),
                                onSubmitted: (_) => _connect(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brand,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _connect,
                                icon: const Icon(
                                  Icons.group_add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Connect',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Current connections
                        ValueListenableBuilder(
                          valueListenable: _store.buddies,
                          builder: (_, list, __) {
                            final buddies = list as List<BuddyLink>;
                            if (buddies.isEmpty) {
                              return const Text(
                                'No buddies yet — add one above.',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final b in buddies)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          b.uid, // you could resolve name via profile if desired
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () async {
                                            await _store.disconnect(b.uid);
                                            _snack('Disconnected');
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Quick one-tap status sender
                _Glass(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Today’s Status',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatusButton(
                              icon: Icons.check_circle_outline,
                              label: 'Done',
                              color: const Color(0xFF22C55E),
                              onTap: () => _store.sendStatus(
                                status: BuddyStatus.done,
                                note: _noteCtrl.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusButton(
                              icon: Icons.hourglass_bottom,
                              label: 'Partly',
                              color: const Color(0xFFF59E0B),
                              onTap: () => _store.sendStatus(
                                status: BuddyStatus.partly,
                                note: _noteCtrl.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusButton(
                              icon: Icons.cancel_outlined,
                              label: 'Didn’t',
                              color: const Color(0xFFE11D48),
                              onTap: () => _store.sendStatus(
                                status: BuddyStatus.missed,
                                note: _noteCtrl.text,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 300,
                              child: TextField(
                                controller: _noteCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Optional note to buddy…',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Feed
                _Glass(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Check-Ins from Buddy',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ValueListenableBuilder(
                          valueListenable: _store.feed,
                          builder: (_, list, __) {
                            final items = (list as List<BuddyFeedItem>);
                            if (items.isEmpty) {
                              return const _EmptyFeed();
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _FeedTile(
                                item: items[i],
                                onEncourage: (toUid, msg) {
                                  _store.sendEncouragement(
                                    toUid: toUid,
                                    message: msg,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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

class _FeedTile extends StatelessWidget {
  final BuddyFeedItem item;
  final void Function(String toUid, String message) onEncourage;
  const _FeedTile({required this.item, required this.onEncourage});

  Color get _color {
    if (item.type == 'encouragement') return const Color(0xFF6366F1);
    switch (item.status) {
      case BuddyStatus.done:
        return const Color(0xFF22C55E);
      case BuddyStatus.partly:
        return const Color(0xFFF59E0B);
      case BuddyStatus.missed:
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final title = item.type == 'encouragement'
        ? 'Encouragement'
        : switch (item.status) {
            BuddyStatus.done => 'Done',
            BuddyStatus.partly => 'Partly',
            BuddyStatus.missed => 'Didn’t',
            _ => 'Update',
          };
    final when =
        '${item.createdAt.month}/${item.createdAt.day} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.favorite_outline, color: c),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.withOpacity(.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                title,
                style: TextStyle(color: c, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Text(when, style: const TextStyle(color: Color(0xFF111827))),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.note != null && item.note!.isNotEmpty)
                Text(
                  item.note!,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  if (item.hours != null)
                    _pill('Hours: ${item.hours!.toStringAsFixed(1)}'),
                  if (item.sleep != null)
                    _pill('Sleep: ${item.sleep!.toStringAsFixed(1)}'),
                  if (item.mood != null) _pill('Mood: ${item.mood}'),
                  if (item.level != null) _pill('Level: ${item.level}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => onEncourage(item.fromUid, 'Nice job! 🚀'),
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    label: const Text('Encourage'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      s,
      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
    ),
  );
}

class _StatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatusButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  const _Glass({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.96),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.favorite_border, color: Color(0xFF8B5CF6), size: 32),
          SizedBox(height: 8),
          Text('No check-ins yet', style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
