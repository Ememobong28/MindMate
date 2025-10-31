import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Profile {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final bool shareMood;
  final bool shareHours;
  final bool shareSleep;
  final bool shareRisk;

  const Profile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.shareMood,
    required this.shareHours,
    required this.shareSleep,
    required this.shareRisk,
  });

  factory Profile.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const <String, dynamic>{};
    final priv = (data['privacy'] as Map?) ?? const {};
    return Profile(
      uid: d.id,
      displayName: (data['displayName'] as String? ?? '').trim(),
      email: (data['email'] as String? ?? ''),
      role: (data['role'] as String? ?? 'student'),
      shareMood: (priv is Map ? (priv['shareMood'] as bool?) : null) ?? false,
      shareHours: (priv is Map ? (priv['shareHours'] as bool?) : null) ?? false,
      shareSleep: (priv is Map ? (priv['shareSleep'] as bool?) : null) ?? false,
      shareRisk: (priv is Map ? (priv['shareRisk'] as bool?) : null) ?? false,
    );
  }
}

class ProfileStore {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  final ValueNotifier<Profile?> profile = ValueNotifier<Profile?>(null);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  User? get _user => FirebaseAuth.instance.currentUser;
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  /// Create user doc if missing (merge so we never wipe fields).
  Future<void> _ensureDoc() async {
    final u = _user;
    if (u == null) return;
    final ref = _doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'displayName': (u.displayName ?? '').trim().isEmpty
            ? (u.email ?? '').split('@').first
            : u.displayName,
        'email': u.email ?? '',
        'emailLower': (u.email ?? '').toLowerCase(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'privacy': {
          'shareMood': false,
          'shareHours': false,
          'shareSleep': false,
          'shareRisk': false,
        },
      }, SetOptions(merge: true));
    }
  }

  /// Start listening for profile changes; self-heal if doc missing.
  Future<void> start() async {
    await _sub?.cancel();
    _sub = null;

    final u = _user;
    if (u == null) {
      profile.value = null;
      return;
    }

    // Ensure the doc exists once
    await _ensureDoc();

    // 🚀 Immediately show an optimistic profile so UI doesn't spin
    profile.value = Profile(
      uid: u.uid,
      displayName: (u.displayName ?? '').trim().isEmpty
          ? (u.email ?? '').split('@').first
          : (u.displayName ?? ''),
      email: u.email ?? '',
      role: 'student',
      shareMood: false,
      shareHours: false,
      shareSleep: false,
      shareRisk: false,
    );

    final ref = _doc(u.uid);

    // Live updates (will replace the optimistic profile)
    _sub = ref.snapshots().listen(
      (snap) async {
        if (!snap.exists) {
          // If deleted, recreate and wait for the next snapshot
          await _ensureDoc();
          return;
        }
        profile.value = Profile.fromDoc(snap);
      },
      onError: (e) {
        debugPrint('Profile listen error: $e');
        // Keep the optimistic profile; don't revert to null/spinner
      },
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    // keep last value so navigating back doesn’t flash spinner
  }

  Future<void> updatePrivacy({
    bool? shareMood,
    bool? shareHours,
    bool? shareSleep,
    bool? shareRisk,
  }) async {
    final u = _user;
    if (u == null) return;
    final ref = _doc(u.uid);
    final update = <String, dynamic>{};
    if (shareMood != null) update['privacy.shareMood'] = shareMood;
    if (shareHours != null) update['privacy.shareHours'] = shareHours;
    if (shareSleep != null) update['privacy.shareSleep'] = shareSleep;
    if (shareRisk != null) update['privacy.shareRisk'] = shareRisk;
    update['updatedAt'] = FieldValue.serverTimestamp();
    // Use set(merge:true) to be safe even if doc gets recreated.
    await ref.set(update, SetOptions(merge: true));
  }

  Future<void> signOut({BuildContext? context}) async {
    await stop();
    await FirebaseAuth.instance.signOut();
    if (context != null && context.mounted) {
      // Make sure your MaterialApp `home` is AuthGate so this returns there.
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    }
  }
}
