import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/history.dart';
import '../widgets/shell_scaffold.dart';
import './insights_screen.dart';
import './home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './commitments_screen.dart';
import 'buddy_screen.dart';
import './profile_screen.dart';


class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});
  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  static const brand = Color(0xFF6D28D9);
  static const pageBg1 = Color(0xFFF5F6FF);
  static const pageBg2 = Color(0xFFEFF2FF);

  double _hours = 0;
  double _sleep = 7;
  int _moodIdx = 2; // 0..4 (Very Low -> Great)
  bool _loading = false;
  String? _err;
  PredictResponse? _result;

  String get _moodString {
    if (_moodIdx <= 1) return 'sad';
    if (_moodIdx == 2) return 'neutral';
    return 'happy';
  }

  Future<void> _runPredict() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _err = null;
      _result = null;
    });
    try {
      final r = await Api.predict(
        hoursStudied: _hours,
        sleepHours: _sleep,
        mood: _moodString,
      );
      setState(() => _result = r);

      await HistoryStore.instance.add(
        HistoryEntry(
          ts: DateTime.now(),
          hours: _hours,
          sleep: _sleep,
          mood: _moodString,
          level: r.stressLevel,
          email: FirebaseAuth.instance.currentUser?.email,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Check-in saved')));
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      current: AppPage.checkin,
      onGoDashboard: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
            constraints: const BoxConstraints(maxWidth: 1000), // ⬅️ tighter
            child: LayoutBuilder(
              builder: (context, c) {
                final isNarrow = c.maxWidth < 900;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    28,
                  ), // ⬅️ tighter
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Daily Check-In 💜',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall // ⬅️ smaller
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3B0764),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take a moment to reflect on your day',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 14),

                      // Two-column responsive layout
                      Flex(
                        direction: isNarrow ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT: Form card
                          Expanded(
                            flex: 3,
                            child: _Glass(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  16,
                                ), // ⬅️ tighter
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome_outlined,
                                          color: brand,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _dateLabel(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    _SectionTitle(
                                      icon: Icons
                                          .sentiment_satisfied_alt_outlined,
                                      title: 'How are you feeling today?',
                                    ),
                                    const SizedBox(height: 8),
                                    _MoodPicker(
                                      index: _moodIdx,
                                      onChanged: (i) =>
                                          setState(() => _moodIdx = i),
                                    ),
                                    const SizedBox(height: 14),

                                    _SectionTitle(
                                      icon: Icons.menu_book_rounded,
                                      title: 'How many hours did you study?',
                                    ),
                                    const SizedBox(height: 8),
                                    _SliderWithBox(
                                      value: _hours,
                                      min: 0,
                                      max: 12,
                                      divisions: 120,
                                      unit: 'h',
                                      onChanged: (v) =>
                                          setState(() => _hours = v),
                                    ),
                                    const SizedBox(height: 14),

                                    _SectionTitle(
                                      icon: Icons.nights_stay_rounded,
                                      title:
                                          'How much did you sleep last night?',
                                    ),
                                    const SizedBox(height: 8),
                                    _SliderWithBox(
                                      value: _sleep,
                                      min: 3,
                                      max: 12,
                                      divisions: 90,
                                      unit: 'h',
                                      onChanged: (v) =>
                                          setState(() => _sleep = v),
                                    ),

                                    if (_err != null) ...[
                                      const SizedBox(height: 12),
                                      _ErrorBanner(msg: _err!),
                                    ],

                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _PrimaryGradientButton(
                                        label: _loading
                                            ? 'Predicting…'
                                            : 'Complete Check-In',
                                        icon: Icons.check_circle_outline,
                                        loading: _loading,
                                        onTap: _loading ? null : _runPredict,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            width: isNarrow ? 0 : 14,
                            height: isNarrow ? 14 : 0,
                          ),

                          // RIGHT: Result / tips panel
                          SizedBox(
                            width: isNarrow
                                ? double.infinity
                                : 340, // ⬅️ slimmer
                            child: _Glass(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  16,
                                ), // ⬅️ tighter
                                child: _result == null
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Your result',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'No prediction yet — complete your check-in to see insights.',
                                            style: TextStyle(
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      )
                                    : _ResultBanner(result: _result!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel() {
    final d = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const wds = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${wds[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

/// ——— UI bits ———

class _Glass extends StatelessWidget {
  final Widget child;
  const _Glass({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5, // ⬅️ slightly lighter
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6D28D9), size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _MoodPicker extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _MoodPicker({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('😢', 'Very Low'),
      ('☹️', 'Low'),
      ('😐', 'Okay'),
      ('🙂', 'Good'),
      ('😄', 'Great'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
              child: _MoodCard(
                emoji: items[i].$1,
                label: items[i].$2,
                selected: i == index,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MoodCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: selected ? const Color(0xFF8B5CF6) : const Color(0xFFE5E7EB),
      width: 2,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 96, // ⬅️ smaller
        height: 84, // ⬅️ smaller
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: border,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderWithBox extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final ValueChanged<double> onChanged;
  const _SliderWithBox({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final vStr = value.toStringAsFixed(0);
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '$vStr $unit',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 54, // ⬅️ smaller
          height: 38, // ⬅️ smaller
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            vStr,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onTap;
  const _PrimaryGradientButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 48, // ⬅️ smaller
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ), // ⬅️ tighter
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        border: Border.all(color: const Color(0xFFE11D48)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Color(0xFF991B1B)),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final PredictResponse result;
  const _ResultBanner({required this.result});

  Color get _color {
    switch (result.stressLevel) {
      case 0:
        return const Color(0xFF22C55E);
      case 1:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFE11D48);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your result',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12), // ⬅️ tighter
          decoration: BoxDecoration(
            color: c.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withOpacity(.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_alt_outlined, color: c, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${result.emoji}  ${result.label}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: c),
                  ),
                  const Spacer(),
                  Text(
                    'Conf: ${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _pill('Hours: ${result.drivers['hours_studied']}'),
                  _pill('Sleep: ${result.drivers['sleep_hours']}'),
                  _pill('Mood: ${result.drivers['mood_score']}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.tip,
                style: const TextStyle(color: Color(0xFF111827)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String s) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ), // ⬅️ tighter
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
