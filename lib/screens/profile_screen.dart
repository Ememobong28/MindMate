import 'package:besmart_project/screens/buddy_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/shell_scaffold.dart';
import '../services/profile_store.dart';
import 'home_screen.dart';
import 'predict_screen.dart';
import 'insights_screen.dart';
import 'commitments_screen.dart';
import 'buddy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const brand = Color(0xFF6D28D9);
  final _store = ProfileStore.instance;

  @override
  void initState() {
    super.initState();
    _store.start();
  }

  @override
  void dispose() {
    _store.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      current: AppPage.profile,
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: ValueListenableBuilder<Profile?>(
              valueListenable: _store.profile,
              builder: (context, p, _) {
                if (p == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile & Settings ⚙️',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3B0764),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your account and privacy preferences',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header card
                    _Glass(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFFEDE9FE),
                              child: Text(
                                (p.displayName.isNotEmpty
                                        ? p.displayName[0]
                                        : (p.email.isNotEmpty
                                              ? p.email[0]
                                              : 'U'))
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: brand,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.displayName.isEmpty
                                        ? p.email
                                        : p.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.email,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  if (p.role.isNotEmpty)
                                    const SizedBox(height: 4),
                                  if (p.role.isNotEmpty)
                                    const Text(
                                      'Admin',
                                      style: TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Privacy settings section
                    _SectionTitle('Privacy Settings'),
                    const SizedBox(height: 10),

                    _Glass(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _InfoBanner(
                              title: 'Privacy First',
                              text:
                                  "By default, your buddy only sees commitment status (green/yellow/red). Toggle options below to share additional wellness data with your accountability buddy.",
                            ),
                            const SizedBox(height: 10),

                            _ToggleTile(
                              title: 'Share Mood Data',
                              subtitle:
                                  'Let your buddy see your daily mood ratings',
                              value: p.shareMood,
                              onChanged: (v) =>
                                  _store.updatePrivacy(shareMood: v),
                            ),
                            _ToggleTile(
                              title: 'Share Study Hours',
                              subtitle:
                                  'Let your buddy see how many hours you study',
                              value: p.shareHours,
                              onChanged: (v) =>
                                  _store.updatePrivacy(shareHours: v),
                            ),
                            _ToggleTile(
                              title: 'Share Sleep Data',
                              subtitle:
                                  'Let your buddy see your sleep patterns',
                              value: p.shareSleep,
                              onChanged: (v) =>
                                  _store.updatePrivacy(shareSleep: v),
                            ),
                            _ToggleTile(
                              title: 'Share Burnout Risk',
                              subtitle:
                                  'Let your buddy see your AI-calculated burnout risk',
                              value: p.shareRisk,
                              onChanged: (v) =>
                                  _store.updatePrivacy(shareRisk: v),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Logout
                    _Glass(
                      tint: const Color(0xFFFFF7ED),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Color(0xFFEA580C)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                // optional: visual feedback
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Signing out...'),
                                  ),
                                );

                                await _store.signOut(
                                  context: context,
                                ); // 👈 pass context for navigation
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ——— UI helpers ———

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.tint});
  final Widget child;
  final Color? tint;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          color: (tint ?? Colors.white).withOpacity(.96),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.security_outlined, color: Color(0xFF6D28D9)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF6B7280)),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
