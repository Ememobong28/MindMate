import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/history.dart';
import '../services/commitments_store.dart';

import 'predict_screen.dart';
import 'insights_screen.dart';
import 'commitments_screen.dart';
import '../widgets/shell_scaffold.dart';
import 'buddy_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Brand palette
  static const Color brand = Color(0xFF6D28D9);
  static const Color brandLight = Color(0xFF8B5CF6);
  static const Color pageBg1 = Color(0xFFF5F6FF);
  static const Color pageBg2 = Color(0xFFEFF2FF);

  final _commitStore = CommitmentsStore.instance;

  @override
  void initState() {
    super.initState();
    _commitStore.start(); // live listen to today's commitments
  }

  String _firstName(User? u) {
    final dn = u?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn.split(RegExp(r'\s+')).first;
    final em = u?.email ?? 'Friend';
    return em.contains('@') ? em.split('@').first : em;
  }

  int _moodScore(String mood) {
    switch (mood) {
      case 'happy':
        return 5;
      case 'neutral':
        return 3;
      case 'sad':
        return 2;
      default:
        return 0;
    }
  }

  ({
    String moodLabel,
    String moodOutOf5,
    String hoursAvg,
    String sleepAvg,
    int risk,
  })
  _computeSnapshot(List<HistoryEntry> list) {
    if (list.isEmpty) {
      return (
        moodLabel: '-',
        moodOutOf5: '- / 5',
        hoursAvg: '-',
        sleepAvg: '-',
        risk: 0,
      );
    }
    final last = list.last;
    final moodScore = _moodScore(last.mood);
    final recent = list.length <= 7 ? list : list.sublist(list.length - 7);
    final hoursAvg =
        (recent.map((e) => e.hours).fold<double>(0, (a, b) => a + b) /
        recent.length);
    final sleepAvg =
        (recent.map((e) => e.sleep).fold<double>(0, (a, b) => a + b) /
        recent.length);
    return (
      moodLabel: last.mood.isEmpty
          ? '-'
          : last.mood[0].toUpperCase() + last.mood.substring(1),
      moodOutOf5: '${moodScore == 0 ? '-' : moodScore} / 5',
      hoursAvg: hoursAvg.toStringAsFixed(1),
      sleepAvg: sleepAvg.toStringAsFixed(1),
      risk: last.level,
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = _firstName(FirebaseAuth.instance.currentUser);

    return ShellScaffold(
      current: AppPage.dashboard,
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
      onGoBuddy: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BuddyScreen()),
      ),
      onGoProfile: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      body: ValueListenableBuilder<List<HistoryEntry>>(
        valueListenable: HistoryStore.instance.entries,
        builder: (context, list, _) {
          final snap = _computeSnapshot(list);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF3B0764),
                                  ),
                              children: [
                                const TextSpan(text: 'Welcome back, '),
                                TextSpan(
                                  text: '$first! ',
                                  style: const TextStyle(color: brand),
                                ),
                                const WidgetSpan(
                                  child: Text(
                                    '👋',
                                    style: TextStyle(fontSize: 28),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Here's your wellness snapshot for today",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: const Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    _GradientButton(
                      icon: Icons.add,
                      label: 'Daily Check-In',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PredictScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stat cards
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _StatCard(
                      width: 320,
                      icon: Icons.sentiment_satisfied_alt_rounded,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: brand,
                      title: 'Mood',
                      valueLarge: snap.moodOutOf5,
                      valueSmall: snap.moodLabel,
                    ),
                    _StatCard(
                      width: 320,
                      icon: Icons.menu_book_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Study Hours',
                      valueLarge: snap.hoursAvg,
                      valueSmall: 'hrs avg',
                    ),
                    _StatCard(
                      width: 320,
                      icon: Icons.nights_stay_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'Sleep',
                      valueLarge: snap.sleepAvg,
                      valueSmall: 'hrs avg',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Risk banner
                _RiskBanner(level: snap.risk),

                const SizedBox(height: 16),

                // Commitments preview (live)
                ValueListenableBuilder<List<Commitment>>(
                  valueListenable: _commitStore.items,
                  builder: (context, items, _) {
                    return _CommitmentsCard(
                      items: items.take(3).toList(),
                      onToggle: (id, v) => _commitStore.toggleDone(id, v),
                      onSetFirst: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommitmentsScreen(),
                          ),
                        );
                      },
                      onViewAll: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommitmentsScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------- UI bits ----------

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: const [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Daily Check-In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String valueLarge;
  final String valueSmall;
  const _StatCard({
    required this.width,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.valueLarge,
    required this.valueSmall,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          valueLarge,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          valueSmall,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  final int level; // 0 low, 1 med, 2 high
  const _RiskBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color tint;
    late final Color chip;
    switch (level) {
      case 2:
        label = 'High Risk';
        tint = const Color(0xFFFFF7ED);
        chip = const Color(0xFFEA580C);
        break;
      case 1:
        label = 'Medium Risk';
        tint = const Color(0xFFFEFCE8);
        chip = const Color(0xFFCA8A04);
        break;
      default:
        label = 'Low Risk';
        tint = const Color(0xFFF0FDF4);
        chip = const Color(0xFF16A34A);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              color: Color(0xFF10B981),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Burnout Risk\nLog your daily data to get personalized wellness insights.',
                style: TextStyle(color: Color(0xFF334155), height: 1.25),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chip.withOpacity(.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: chip),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(color: chip, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommitmentsCard extends StatelessWidget {
  final List<Commitment> items; // preview (0..3)
  final void Function(String id, bool v) onToggle;
  final VoidCallback onSetFirst;
  final VoidCallback onViewAll;

  const _CommitmentsCard({
    required this.items,
    required this.onToggle,
    required this.onSetFirst,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = items.isNotEmpty;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 12),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today's Commitments",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                OutlinedButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!hasAny)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFFBFAFF),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      color: _HomeScreenState.brandLight,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No commitments set for today',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onSetFirst,
                      icon: const Icon(Icons.add),
                      label: const Text('Set Your First Commitment'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (final c in items) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBFAFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: c.done,
                            onChanged: (v) => onToggle(c.id, v ?? false),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.text,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                                decoration: c.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
