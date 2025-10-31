import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  static const _brand = Color(0xFF6D28D9);
  static const _brandLight = Color(0xFF8B5CF6);

  late final AnimationController _heroCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  late final AnimationController _illusCtrl;
  late final Animation<double> _illusFade;
  late final Animation<Offset> _illusSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut));

    _illusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _illusFade = CurvedAnimation(parent: _illusCtrl, curve: Curves.easeOut);
    _illusSlide = Tween<Offset>(
      begin: const Offset(.04, .06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _illusCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _illusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top nav
                  Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [_brandLight, _brand],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'MindMate',
                            style: t.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text('Log in'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: const Text('Get Started'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Hero
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 900;
                      return Flex(
                        direction: narrow ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FadeTransition(
                              opacity: _fadeIn,
                              child: SlideTransition(
                                position: _slideUp,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your wellness companion for school',
                                      style: t.displaySmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF3B0764),
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Check in daily, set micro-commitments, and stay accountable with a buddy — private by default.',
                                      style: t.titleMedium?.copyWith(
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Trust / Stats row
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 12,
                                      children: const [
                                        _StatPill(
                                          icon: Icons.check_circle_outline,
                                          title: 'Micro-commitments',
                                          value: '1–3 per day',
                                        ),
                                        _StatPill(
                                          icon: Icons.lock_outline,
                                          title: 'Privacy',
                                          value: 'You control sharing',
                                        ),
                                        _StatPill(
                                          icon: Icons.bolt_outlined,
                                          title: '1-tap check-in',
                                          value: '< 10 seconds',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: narrow ? 0 : 20,
                            height: narrow ? 20 : 0,
                          ),

                          // Right “illustration” / app preview card
                          Expanded(
                            child: FadeTransition(
                              opacity: _illusFade,
                              child: SlideTransition(
                                position: _illusSlide,
                                child: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x11000000),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'What you can do',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _feature(
                                          icon: Icons.favorite_border,
                                          title: 'Daily Check-In',
                                          desc:
                                              'Track study hours, sleep, and mood to get burnout risk.',
                                        ),
                                        _feature(
                                          icon: Icons.task_alt_outlined,
                                          title: 'Micro-Commitments',
                                          desc:
                                              'Set 1–3 daily goals and celebrate wins.',
                                        ),
                                        _feature(
                                          icon: Icons.groups_2_outlined,
                                          title: 'Accountability Buddy',
                                          desc:
                                              'One-tap Done/Partly/Missed with quick encouragement.',
                                        ),
                                        _feature(
                                          icon: Icons.lock_outline,
                                          title: 'Privacy First',
                                          desc:
                                              'Private by default — share only what you choose.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // Feature grid (three cards)
                  Text(
                    'Why students love MindMate',
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 900;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _FeatureCard(
                            icon: Icons.insights_outlined,
                            title: 'Clear insights',
                            desc:
                                'Simple visuals help you spot patterns in study, sleep, and stress.',
                          ),
                          _FeatureCard(
                            icon: Icons.notifications_active_outlined,
                            title: 'Gentle nudges',
                            desc:
                                'Optional reminders to add your 10-second daily check-in.',
                          ),
                          _FeatureCard(
                            icon: Icons.handshake_outlined,
                            title: 'Buddy support',
                            desc:
                                'Lightweight accountability with positive feedback loops.',
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Testimonials
                  Text(
                    'What students say',
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: const [
                      _Testimonial(
                        quote:
                            '“It takes me under a minute and keeps me honest. My exams week felt way more organized.”',
                        name: 'Imani • CS Major',
                      ),
                      _Testimonial(
                        quote:
                            '“Buddy pings are clutch. A quick ‘you got this’ is weirdly motivating.”',
                        name: 'Diego • Nursing',
                      ),
                      _Testimonial(
                        quote:
                            '“Finally a wellness tool that respects privacy.”',
                        name: 'Sofia • Math',
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // FAQ
                  Text(
                    'FAQ',
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _FaqItem(
                    q: 'Is my data private?',
                    a: 'Yes. Everything is private by default. You choose what to share, if anything, with your buddy.',
                  ),
                  const _FaqItem(
                    q: 'Do I need to check in every day?',
                    a: 'No. Check in whenever you want. The more consistent, the better your insights.',
                  ),
                  const _FaqItem(
                    q: 'Is MindMate free?',
                    a: 'The core student features are free. Future premium features will be optional.',
                  ),

                  const SizedBox(height: 36),

                  // Footer CTA
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Ready to feel more in control of your semester?',
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _brand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: const Text('Get Started — it’s free'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '© ${DateTime.now().year} MindMate — Built for students',
                          style: t.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
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

  Widget _feature({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _brand, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6D28D9)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text('• $value', style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x11000000), blurRadius: 12),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF6D28D9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: const TextStyle(color: Color(0xFF6B7280)),
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

class _MockScreen extends StatefulWidget {
  const _MockScreen({required this.title});
  final String title;

  @override
  State<_MockScreen> createState() => _MockScreenState();
}

class _MockScreenState extends State<_MockScreen> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 250,
        height: 150,
        padding: const EdgeInsets.all(12),
        transform: _hover
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0x22000000),
              blurRadius: _hover ? 20 : 12,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: _hover ? const Color(0xFF6D28D9) : const Color(0xFFE5E7EB),
          ),
          gradient: _hover
              ? const LinearGradient(
                  colors: [Color(0xFFFBFAFF), Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Preview',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Testimonial extends StatelessWidget {
  const _Testimonial({required this.quote, required this.name});
  final String quote;
  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote, color: Color(0xFF6D28D9)),
              const SizedBox(height: 8),
              Text(
                quote,
                style: const TextStyle(color: Color(0xFF111827), height: 1.35),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _open = !_open),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.q,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.a,
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                ),
                crossFadeState: _open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
