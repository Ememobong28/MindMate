import 'package:flutter/material.dart';
import '../auth/auth_service_web.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // --- Brand tokens (match login) ---
  static const _brand = Color(0xFF4F46E5);
  static const _bg1 = Color(0xFFEEF2FF);
  static const _bg2 = Color(0xFFE0E7FF);

  // --- Form + state ---
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // --- Validation + strength helpers ---
  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);
    if (!ok) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Password is required';
    if (s.length < 6) return 'Use at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Please confirm your password';
    if (s != _password.text.trim()) return 'Passwords do not match';
    return null;
  }

  double _passwordStrength(String s) {
    if (s.isEmpty) return 0;
    double score = 0;
    if (s.length >= 6) score += 0.25;
    if (s.length >= 8) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(s)) score += 0.15;
    if (RegExp(r'[a-z]').hasMatch(s)) score += 0.15;
    if (RegExp(r'\d').hasMatch(s)) score += 0.1;
    if (RegExp(r'[^\w\s]').hasMatch(s)) score += 0.1;
    return score.clamp(0, 1);
  }

  Color _strengthColor(double v) {
    if (v < 0.34) return const Color(0xFFE11D48); // red
    if (v < 0.67) return const Color(0xFFF59E0B); // amber
    return const Color(0xFF22C55E); // green
  }

  String _strengthLabel(double v) {
    if (v < 0.34) return 'Weak';
    if (v < 0.67) return 'Medium';
    return 'Strong';
  }

  Widget _reqRow(bool ok, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: ok ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ok ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('email-already-in-use'))
      return 'An account with that email already exists.';
    if (s.contains('invalid-email')) return 'Enter a valid email address.';
    if (s.contains('weak-password')) return 'Password is too weak.';
    if (s.contains('network')) return 'Network error. Check connection.';
    return 'Sign up failed. Please try again.';
  }

  Future<void> _signupEmail() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await authWeb.signUpWithEmail(_email.text.trim(), _password.text.trim());
      if (mounted)
        Navigator.of(context).pop(); // back to login; stream will move to home
    } catch (e) {
      setState(() => _errorText = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signupGoogle() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      // For web, this both signs in and "signs up" if the Google account is new.
      await authWeb.signInWithGooglePopup();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorText = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pwd = _password.text;
    final strength = _passwordStrength(pwd);

    final hasLen6 = pwd.length >= 6;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
    final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
    final hasDigit = RegExp(r'\d').hasMatch(pwd);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [_bg1, _bg2],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: _glassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: const BoxDecoration(
                              color: _brand,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Create your account',
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join MindMate to track and improve your study wellness.',
                        style: t.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),

                      if (_errorText != null) ...[
                        _errorBanner(_errorText!),
                        const SizedBox(height: 12),
                      ],

                      // --- Google sign up button at top (fast path) ---
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: _loading ? null : _signupGoogle,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 20,
                                width: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.g_mobiledata,
                                  size: 20,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Sign up with Google'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      _orDivider(),
                      const SizedBox(height: 14),

                      // --- Email sign up form ---
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              validator: _validateEmail,
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.mail_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              focusNode: _passwordFocus,
                              obscureText: _obscure1,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: _validatePassword,
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) =>
                                  _confirmFocus.requestFocus(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure1 = !_obscure1),
                                  icon: Icon(
                                    _obscure1
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  tooltip: _obscure1
                                      ? 'Show password'
                                      : 'Hide password',
                                ),
                              ),
                            ),

                            // Strength meter
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      minHeight: 8,
                                      value: strength,
                                      backgroundColor: const Color(0xFFE5E7EB),
                                      color: _strengthColor(strength),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _strengthLabel(strength),
                                  style: t.bodySmall?.copyWith(
                                    color: _strengthColor(strength),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                children: [
                                  _reqRow(hasLen6, '6+ chars'),
                                  _reqRow(hasUpper, 'Uppercase'),
                                  _reqRow(hasLower, 'Lowercase'),
                                  _reqRow(hasDigit, 'Number'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirm,
                              focusNode: _confirmFocus,
                              obscureText: _obscure2,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: _validateConfirm,
                              onFieldSubmitted: (_) => _signupEmail(),
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure2 = !_obscure2),
                                  icon: Icon(
                                    _obscure2
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  tooltip: _obscure2 ? 'Show' : 'Hide',
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text.rich(
                                TextSpan(
                                  text:
                                      'By creating an account, you agree to our ',
                                  children: [
                                    TextSpan(
                                      text: 'Terms',
                                      style: const TextStyle(
                                        color: _brand,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                        color: _brand,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                                style: t.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: _brand,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _loading ? null : _signupEmail,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Create account'),
                              ),
                            ),
                            const SizedBox(height: 8),

                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text(
                                'Already have an account? Sign in',
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
        ),
      ),
    );
  }

  // --- UI helpers ---
  Widget _glassCard({required Widget child}) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          backgroundBlendMode: BlendMode.overlay,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        border: Border.all(color: const Color(0xFFE11D48)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE11D48)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(color: Color(0xFF991B1B))),
          ),
          IconButton(
            onPressed: () => setState(() => _errorText = null),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF991B1B)),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or'),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
      ],
    );
  }
}
