import 'package:besmart_project/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/shell_scaffold.dart';
import './home_screen.dart';
import './predict_screen.dart';
import './insights_screen.dart';
import '../services/commitments_store.dart';
import './buddy_screen.dart';
import 'predict_screen.dart';

class CommitmentsScreen extends StatefulWidget {
  const CommitmentsScreen({super.key});
  @override
  State<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends State<CommitmentsScreen> {
  static const brand = Color(0xFF6D28D9);
  final _controller = TextEditingController();
  final _store = CommitmentsStore.instance;

  @override
  void initState() {
    super.initState();
    _store.start(); // listen to today
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await _store.add(text);
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      current: AppPage.commitments,
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
      onGoBuddy: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BuddyScreen()),
      ),
      onGoProfile: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      onGoCommitments: () {}, // already here
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'My Commitments ✨',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3B0764),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set up to ${CommitmentsStore.maxItems} micro-commitments for today',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),

                // Add card
                _Glass(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Commitment',
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
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText:
                                      'e.g., Study for 45 mins, Review lecture notes…',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onSubmitted: (_) => _add(),
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
                                onPressed: _add,
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Add',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ValueListenableBuilder<List<Commitment>>(
                          valueListenable: _store.items,
                          builder: (_, list, __) => Text(
                            '${list.length}/${CommitmentsStore.maxItems} commitments set',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // List / Empty state
                ValueListenableBuilder<List<Commitment>>(
                  valueListenable: _store.items,
                  builder: (_, list, __) {
                    if (list.isEmpty) {
                      return const _EmptyState();
                    }
                    return Column(
                      children: [
                        for (final c in list) ...[
                          _CommitmentTile(
                            text: c.text,
                            done: c.done,
                            onToggle: (v) => _store.toggleDone(c.id, v),
                            onRemove: () => _store.remove(c.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommitmentTile extends StatelessWidget {
  const _CommitmentTile({
    required this.text,
    required this.done,
    required this.onToggle,
    required this.onRemove,
  });
  final String text;
  final bool done;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Checkbox(value: done, onChanged: (v) => onToggle(v ?? false)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 40),
        CircleAvatar(
          radius: 32,
          backgroundColor: Color(0xFFEDE9FE),
          child: Icon(Icons.add, color: Color(0xFF8B5CF6), size: 28),
        ),
        SizedBox(height: 12),
        Text(
          'No commitments yet',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Start by adding your first micro-commitment above',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
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
