import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service_web.dart';
import 'signup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Styling tokens (easy to tweak) ---
  static const _brand = Color(0xFF4F46E5);
  static const _bg1 = Color(0xFFEEF2FF);
  static const _bg2 = Color(0xFFE0E7FF);

  // --- Form + state ---
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

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

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('INVALID_LOGIN_CREDENTIALS') || s.contains('wrong-password'))
      return 'Invalid email or password.';
    if (s.contains('user-not-found')) return 'No user found with that email.';
    if (s.contains('too-many-requests')) return 'Too many attempts, try later.';
    if (s.contains('network')) return 'Network error. Check connection.';
    return 'Sign-in failed. Please try again.';
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await authWeb.signInWithEmail(_email.text.trim(), _password.text.trim());
      await upsertCurrentUser();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _errorText = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> upsertCurrentUser() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final uid = u.uid;
    final email = u.email ?? '';
    final emailLower = email.toLowerCase();
    final displayName = (u.displayName ?? '').trim();

    final usersDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final emailIndexDoc = FirebaseFirestore.instance
        .collection('emailIndex')
        .doc(emailLower);

    // Use a batch so both writes land together.
    final batch = FirebaseFirestore.instance.batch();

    // Root user doc (merge keeps existing fields like privacy, createdAt, etc.)
    batch.set(usersDoc, {
      'displayName': displayName.isEmpty ? email.split('@').first : displayName,
      'email': email,
      'emailLower': emailLower,
      'role':
          FieldValue.delete(), // remove if you previously set something else
      'updatedAt': FieldValue.serverTimestamp(),
      // Initialize privacy if missing; merging means existing values won’t be overwritten.
      'privacy': {
        'shareMood': FieldValue.increment(0), // noop if exists; we’ll fix below
        'shareHours': FieldValue.increment(0),
        'shareSleep': FieldValue.increment(0),
        'shareRisk': FieldValue.increment(0),
      },
    }, SetOptions(merge: true));

    // If the document doesn’t exist, set createdAt once.
    final snap = await usersDoc.get();
    if (!snap.exists) {
      batch.set(usersDoc, {
        'createdAt': FieldValue.serverTimestamp(),
        'privacy': {
          'shareMood': false,
          'shareHours': false,
          'shareSleep': false,
          'shareRisk': false,
        },
        'role': 'student',
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final provider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithPopup(provider);

      await upsertCurrentUser();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e, st) {
      debugPrint('Google sign-in failed: $e\n$st');
      setState(() => _errorText = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Enter your email to reset password.');
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      await authWeb.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } catch (e) {
      setState(() => _errorText = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            colors: [_bg1, _bg2],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: _glassCard(
                context: context,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Header / Branding ---
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
                            'MindMate',
                            style: t.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: t.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),

                      // --- Error banner ---
                      if (_errorText != null) ...[
                        _errorBanner(_errorText!),
                        const SizedBox(height: 12),
                      ],

                      // --- Form ---
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
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _loginEmail(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  tooltip: _obscure
                                      ? 'Show password'
                                      : 'Hide password',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Actions row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _loading ? null : _reset,
                                  child: const Text('Forgot password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Primary button
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
                                onPressed: _loading ? null : _loginEmail,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      _orDivider(),
                      const SizedBox(height: 14),

                      // Google button (brand-like, subtle)
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
                          onPressed: _loading ? null : _loginGoogle,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Simple “G” circle
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
                              const Text('Continue with Google'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Footer / link to sign up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No account?'),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpScreen(),
                                      ),
                                    );
                                  },
                            child: const Text('Create one'),
                          ),
                        ],
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

  Widget _glassCard({required BuildContext context, required Widget child}) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          backgroundBlendMode: BlendMode.overlay,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              spreadRadius: 0,
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
