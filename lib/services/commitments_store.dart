import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Commitment {
  final String id;
  final String text;
  final bool done;
  final DateTime createdAt;

  Commitment({
    required this.id,
    required this.text,
    required this.done,
    required this.createdAt,
  });

  factory Commitment.fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const {};
    final ts = data['createdAt'];
    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is DateTime) {
      created = ts;
    } else {
      created = DateTime.now(); // first frame before server ts
    }
    return Commitment(
      id: snap.id,
      text: (data['text'] as String? ?? '').trim(),
      done: (data['done'] as bool?) ?? false,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson({
    required String uid,
    required String email,
    required String dayKey,
  }) => {
    'text': text,
    'done': done,
    'createdAt': FieldValue.serverTimestamp(),
    'dayKey': dayKey,
  };
}

class CommitmentsStore {
  CommitmentsStore._();
  static final CommitmentsStore instance = CommitmentsStore._();

  /// Live list for today
  final ValueNotifier<List<Commitment>> items = ValueNotifier<List<Commitment>>(
    [],
  );

  /// Maximum commitments per day
  static const int maxItems = 3;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  User get _user {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) throw StateError('No user');
    return u;
  }

  String dayKey([DateTime? d]) {
    d ??= DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// users/{uid}/commitments/{yyyy-mm-dd}/items/*
  CollectionReference<Map<String, dynamic>> _col(String dk) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('commitments')
        .doc(dk)
        .collection('items');
  }

  /// Begin listening to **today**; call once after login & keep alive.
  Future<void> start() async {
    await _sub?.cancel();
    final dk = dayKey();
    _sub = _col(dk)
        .orderBy('createdAt')
        .snapshots()
        .listen(
          (qs) => items.value = qs.docs.map(Commitment.fromSnap).toList(),
        );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Add one (enforces cap client-side; you can also enforce in rules)
  Future<void> add(String text) async {
    final dk = dayKey();
    if (items.value.length >= maxItems) {
      throw StateError('Max $maxItems commitments for today');
    }
    final c = Commitment(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}', // temp id
      text: text.trim(),
      done: false,
      createdAt: DateTime.now(),
    );

    // optimistic push so UI feels instant; stream will replace it
    items.value = [...items.value, c];

    await _col(
      dk,
    ).add(c.toJson(uid: _user.uid, email: _user.email ?? '', dayKey: dk));
  }

  Future<void> remove(String id) async {
    final dk = dayKey();
    await _col(dk).doc(id).delete().catchError((_) {});
    items.value = items.value.where((e) => e.id != id).toList();
  }

  Future<void> toggleDone(String id, bool done) async {
    final dk = dayKey();
    await _col(dk).doc(id).update({'done': done}).catchError((_) {});
    items.value = [
      for (final e in items.value)
        if (e.id == id)
          Commitment(id: e.id, text: e.text, done: done, createdAt: e.createdAt)
        else
          e,
    ];
  }
}
