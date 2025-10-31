import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuddyLink {
  final String uid;
  final DateTime createdAt;
  const BuddyLink({required this.uid, required this.createdAt});
}

enum BuddyStatus { done, partly, missed }

class BuddyFeedItem {
  final String id;
  final String type; // 'status' | 'encouragement'
  final String fromUid;
  final String? fromEmail;
  final String? fromName;
  final BuddyStatus? status; // if type = status
  final String? note;
  final int? level; // optional context
  final double? hours;
  final double? sleep;
  final String? mood;
  final DateTime createdAt;

  BuddyFeedItem({
    required this.id,
    required this.type,
    required this.fromUid,
    this.fromEmail,
    this.fromName,
    this.status,
    this.note,
    this.level,
    this.hours,
    this.sleep,
    this.mood,
    required this.createdAt,
  });

  factory BuddyFeedItem.fromSnap(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    DateTime ts;
    final ct = d['createdAt'];
    if (ct is Timestamp)
      ts = ct.toDate();
    else
      ts = DateTime.now();
    BuddyStatus? st;
    final raw = d['status'];
    if (raw == 'done') st = BuddyStatus.done;
    if (raw == 'partly') st = BuddyStatus.partly;
    if (raw == 'missed') st = BuddyStatus.missed;

    return BuddyFeedItem(
      id: s.id,
      type: (d['type'] as String? ?? 'status'),
      fromUid: d['fromUid'] as String? ?? '',
      fromEmail: d['fromEmail'] as String?,
      fromName: d['fromName'] as String?,
      status: st,
      note: d['note'] as String?,
      level: (d['level'] as num?)?.toInt(),
      hours: (d['hours'] as num?)?.toDouble(),
      sleep: (d['sleep'] as num?)?.toDouble(),
      mood: d['mood'] as String?,
      createdAt: ts,
    );
  }
}

class BuddyStore {
  BuddyStore._();
  static final BuddyStore instance = BuddyStore._();

  final ValueNotifier<List<BuddyLink>> buddies = ValueNotifier<List<BuddyLink>>(
    [],
  );
  final ValueNotifier<List<BuddyFeedItem>> feed =
      ValueNotifier<List<BuddyFeedItem>>([]);

  StreamSubscription? _buddiesSub;
  StreamSubscription? _feedSub;

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> _buddiesCol(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('buddies');

  CollectionReference<Map<String, dynamic>> _feedCol(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('buddy_feed');

  Future<void> start() async {
    final u = _user;
    if (u == null) return;

    _buddiesSub?.cancel();
    _feedSub?.cancel();

    _buddiesSub = _buddiesCol(u.uid).orderBy('createdAt').snapshots().listen((
      qs,
    ) {
      buddies.value = [
        for (final d in qs.docs)
          BuddyLink(
            uid: d.id,
            createdAt: (d['createdAt'] is Timestamp)
                ? (d['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          ),
      ];
    });

    _feedSub = _feedCol(u.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((qs) {
          feed.value = [for (final d in qs.docs) BuddyFeedItem.fromSnap(d)];
        });
  }

  Future<void> stop() async {
    await _buddiesSub?.cancel();
    await _feedSub?.cancel();
    _buddiesSub = null;
    _feedSub = null;
  }

  /// Connect to a buddy by their email (case-insensitive).
  Future<void> connectByEmail(String email) async {
    final me = _user;
    if (me == null) throw StateError('Not signed in');
    final emailLower = email.trim().toLowerCase();
    if (emailLower.isEmpty) return;
    if (emailLower == (me.email ?? '').toLowerCase()) {
      throw StateError("You can't add yourself :)");
    }

    // Find target uid by emailLower in profiles
    final snap = await FirebaseFirestore.instance
        .collectionGroup('profile')
        .where('emailLower', isEqualTo: emailLower)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw StateError('No user found for $email');
    }
    final targetUid = snap.docs.first.reference.parent.parent!.id;

    final now = FieldValue.serverTimestamp();
    // Write both sides
    await _buddiesCol(
      me.uid,
    ).doc(targetUid).set({'createdAt': now, 'status': 'active'});
    await _buddiesCol(
      targetUid,
    ).doc(me.uid).set({'createdAt': now, 'status': 'active'});

    // Optional: first hello item in both feeds
    final hello = {
      'type': 'encouragement',
      'fromUid': me.uid,
      'fromEmail': me.email,
      'fromName': me.displayName,
      'note': '👋 Let’s keep each other accountable!',
      'createdAt': now,
    };
    await _feedCol(targetUid).add(hello);
  }

  Future<void> disconnect(String buddyUid) async {
    final me = _user;
    if (me == null) return;
    await _buddiesCol(me.uid).doc(buddyUid).delete();
    await _buddiesCol(buddyUid).doc(me.uid).delete();
  }

  /// Send a one-tap status to ALL active buddies (or pass a specific targetUid).
  Future<void> sendStatus({
    required BuddyStatus status,
    String? note,
    int? level,
    double? hours,
    double? sleep,
    String? mood,
    String? targetUid, // optional single target
  }) async {
    final me = _user;
    if (me == null) throw StateError('Not signed in');

    final now = FieldValue.serverTimestamp();
    final payload = {
      'type': 'status',
      'fromUid': me.uid,
      'fromEmail': me.email,
      'fromName': me.displayName,
      'status': switch (status) {
        BuddyStatus.done => 'done',
        BuddyStatus.partly => 'partly',
        BuddyStatus.missed => 'missed',
      },
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (level != null) 'level': level,
      if (hours != null) 'hours': hours,
      if (sleep != null) 'sleep': sleep,
      if (mood != null) 'mood': mood,
      'createdAt': now,
    };

    final targets = <String>[];
    if (targetUid != null) {
      targets.add(targetUid);
    } else {
      targets.addAll(buddies.value.map((b) => b.uid));
    }

    final batch = FirebaseFirestore.instance.batch();
    for (final uid in targets) {
      batch.set(_feedCol(uid).doc(), payload);
    }
    await batch.commit();
  }

  Future<void> sendEncouragement({
    required String toUid,
    required String message,
  }) async {
    final me = _user;
    if (me == null) throw StateError('Not signed in');
    await _feedCol(toUid).add({
      'type': 'encouragement',
      'fromUid': me.uid,
      'fromEmail': me.email,
      'fromName': me.displayName,
      'note': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
