import 'package:flutter/material.dart';

enum AppPage { dashboard, checkin, insights, commitments, buddy, profile }

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    super.key,
    required this.current,
    required this.body,
    this.onGoDashboard,
    this.onGoCheckIn,
    this.onGoInsights,
    this.onGoCommitments,
    this.onGoBuddy,
    this.onGoProfile,
  });

  final AppPage current;
  final Widget body;

  // Simple callbacks so each screen decides how to navigate.
  final VoidCallback? onGoDashboard;
  final VoidCallback? onGoCheckIn;
  final VoidCallback? onGoInsights;
  final VoidCallback? onGoCommitments;
  final VoidCallback? onGoBuddy;
  final VoidCallback? onGoProfile;

  // Brand
  static const Color brand = Color(0xFF6D28D9);
  static const Color brandLight = Color(0xFF8B5CF6);
  static const Color pageBg1 = Color(0xFFF5F6FF);
  static const Color pageBg2 = Color(0xFFEFF2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg1,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Sidebar(
              current: current,
              onGoDashboard: onGoDashboard,
              onGoCheckIn: onGoCheckIn,
              onGoInsights: onGoInsights,
              onGoCommitments: onGoCommitments,
              onGoBuddy: onGoBuddy,
              onGoProfile: onGoProfile,
            ),
            // Scrollable main area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1, -1),
                    end: Alignment(1, 1),
                    colors: [pageBg1, pageBg2],
                  ),
                ),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.current,
    required this.onGoDashboard,
    required this.onGoCheckIn,
    required this.onGoInsights,
    required this.onGoCommitments,
    required this.onGoBuddy,
    required this.onGoProfile,
  });

  final AppPage current;
  final VoidCallback? onGoDashboard;
  final VoidCallback? onGoCheckIn;
  final VoidCallback? onGoInsights;
  final VoidCallback? onGoCommitments;
  final VoidCallback? onGoBuddy;
  final VoidCallback? onGoProfile;

  static const Color brand = ShellScaffold.brand;
  static const double _w = 250;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _w,
      child: Container(
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MindMate',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Your wellness companion',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: current == AppPage.dashboard,
              onTap: onGoDashboard,
            ),
            _NavItem(
              icon: Icons.favorite_border_rounded,
              label: 'Daily Check-In',
              selected: current == AppPage.checkin,
              onTap: onGoCheckIn,
            ),
            _NavItem(
              icon: Icons.insights_outlined,
              label: 'Insights',
              selected: current == AppPage.insights,
              onTap: onGoInsights,
            ),
            _NavItem(
              icon: Icons.task_alt_outlined,
              label: 'Commitments',
              selected: current == AppPage.commitments,
              onTap: onGoCommitments,
            ),
            _NavItem(
              icon: Icons.groups_2_outlined,
              label: 'My Buddy',
              selected: current == AppPage.buddy,
              onTap: onGoBuddy,
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: current == AppPage.profile,
              onTap: onGoProfile,
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user, size: 18, color: Color(0xFF22C55E)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privacy First\nYour data stays private. Only you control what to share.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFEDE9FE) : Colors.transparent;
    final fg = selected ? ShellScaffold.brand : const Color(0xFF334155);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
