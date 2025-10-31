import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/shell_scaffold.dart';
import '../services/history.dart';
import 'home_screen.dart';
import 'predict_screen.dart';
import 'commitments_screen.dart';
import 'insights_screen.dart' show InsightsScreen;
import 'buddy_screen.dart';
import 'profile_screen.dart';


class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const brand = Color(0xFF6D28D9);
  static const pageBg1 = Color(0xFFF5F6FF);
  static const pageBg2 = Color(0xFFEFF2FF);

  Color _levelColor(int level) => level == 0
      ? const Color(0xFF22C55E)
      : (level == 1 ? const Color(0xFFF59E0B) : const Color(0xFFE11D48));

  String _levelLabel(int level) =>
      level == 0 ? 'Low' : (level == 1 ? 'Med' : 'High');

  Future<void> _exportCsv(BuildContext context) async {
    final csv = HistoryStore.instance.exportCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This will remove all saved predictions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await HistoryStore.instance.clearAll(); // clears local + firestore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('History cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      current: AppPage.insights,
      onGoDashboard: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      ),
      onGoCheckIn: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PredictScreen()),
      ),
      onGoInsights: () {}, // already here
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [pageBg1, pageBg2],
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header + actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Insights & History',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF3B0764),
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your past check-ins and stress predictions',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _exportCsv(context),
                            icon: const Icon(Icons.file_download_outlined),
                            label: const Text('Export CSV'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _confirmClear(context),
                            icon: const Icon(Icons.delete_forever_outlined),
                            label: const Text('Clear All'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE11D48),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    children: const [
                      _LegendDot(color: Color(0xFF22C55E), label: 'Low'),
                      _LegendDot(color: Color(0xFFF59E0B), label: 'Med'),
                      _LegendDot(color: Color(0xFFE11D48), label: 'High'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // List
                  Expanded(
                    child: ValueListenableBuilder<List<HistoryEntry>>(
                      valueListenable: HistoryStore.instance.entries,
                      builder: (context, list, _) {
                        if (list.isEmpty) return const _EmptyInsights();

                        final items = list.reversed.toList();
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final e = items[i];
                            final dt = e.ts;
                            final dateStr =
                                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            final color = _levelColor(e.level);
                            final label = _levelLabel(e.level);

                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  6,
                                  12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.insights, color: color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: color.withOpacity(.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: color,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                dateStr,
                                                style: const TextStyle(
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 6,
                                            children: [
                                              _chip(
                                                'Hours',
                                                e.hours.toStringAsFixed(1),
                                              ),
                                              _chip(
                                                'Sleep',
                                                e.sleep.toStringAsFixed(1),
                                              ),
                                              _chip('Mood', e.mood),
                                              if (e.email != null &&
                                                  e.email!.isNotEmpty)
                                                _chip('User', e.email!),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete entry',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        await HistoryStore.instance.deleteEntry(
                                          e.ts,
                                        );
                                        // ignore: use_build_context_synchronously
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Entry deleted'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Color(0xFF0F172A)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_toggle_off,
              size: 56,
              color: Colors.black45,
            ),
            const SizedBox(height: 10),
            Text(
              'No history yet',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Run a daily check-in to see insights here.',
              style: t.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
