// services/history.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryEntry {
  final DateTime ts;
  final double hours;
  final double sleep;
  final String mood; // 'sad' | 'neutral' | 'happy'
  final int level; // 0 low, 1 med, 2 high
  final String? email;

  HistoryEntry({
    required this.ts,
    required this.hours,
    required this.sleep,
    required this.mood,
    required this.level,
    this.email,
  });

  String get docId => ts.millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'ts': ts.millisecondsSinceEpoch,
    'hours': hours,
    'sleep': sleep,
    'mood': mood,
    'level': level,
    if (email != null) 'email': email,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) {
    final rawTs = j['ts'];
    late DateTime when;
    if (rawTs is int) {
      when = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs is String) {
      when = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      when = DateTime.now();
    }
    return HistoryEntry(
      ts: when,
      hours: (j['hours'] as num).toDouble(),
      sleep: (j['sleep'] as num).toDouble(),
      mood: j['mood'] as String,
      level: j['level'] as int,
      email: j['email'] as String?,
    );
  }
}

class HistoryStore {
  HistoryStore._();
  static final HistoryStore instance = HistoryStore._();

  static const _kKey = 'mindmate_history_v2';

  final ValueNotifier<List<HistoryEntry>> entries =
      ValueNotifier<List<HistoryEntry>>([]);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _fsSub;

  /// Call **once** after Firebase.initializeApp().
  /// - Loads local cache immediately
  /// - Subscribes to FirebaseAuth changes
  /// - When a user is signed in, attaches a Firestore listener for `/users/{uid}/history`
  Future<void> start() async {
    await _loadLocal();

    // react to login/logout and rewire Firestore listener
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _wireFirestore(user);
    });

    // also wire right now for the current user (in case already signed in)
    _wireFirestore(FirebaseAuth.instance.currentUser);
  }

  /// Stop all listeners if ever needed.
  Future<void> dispose() async {
    await _authSub?.cancel();
    await _fsSub?.cancel();
    _authSub = null;
    _fsSub = null;
  }

  // ---------- Public Actions ----------

  Future<void> add(HistoryEntry e) async {
    final u = FirebaseAuth.instance.currentUser;
    final entry = e.email == null && u?.email != null
        ? HistoryEntry(
            ts: e.ts,
            hours: e.hours,
            sleep: e.sleep,
            mood: e.mood,
            level: e.level,
            email: u!.email,
          )
        : e;

    if (u != null) {
      await _col(u.uid).doc(entry.docId).set(entry.toJson());
      // optimistic local update (listener will also sync)
      _mergeLocal([entry]);
      await _saveLocal();
      return;
    }

    // offline/local-only
    _mergeLocal([entry]);
    await _saveLocal();
  }

  Future<void> deleteEntry(DateTime ts) async {
    final id = ts.millisecondsSinceEpoch.toString();
    final u = FirebaseAuth.instance.currentUser;

    if (u != null) {
      await _col(u.uid).doc(id).delete();
    }
    entries.value = [...entries.value]..removeWhere((e) => e.ts == ts);
    await _saveLocal();
  }

  Future<void> clearAll() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      final qs = await _col(u.uid).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in qs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    entries.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  List<HistoryEntry> recent(int n) {
    final list = entries.value;
    return list.length <= n ? list : list.sublist(list.length - n);
  }

  String exportCsv() {
    final rows = <String>[
      'timestamp,hours,sleep,mood,level,email',
      ...entries.value.map(
        (e) =>
            '${e.ts.toIso8601String()},'
            '${e.hours.toStringAsFixed(2)},'
            '${e.sleep.toStringAsFixed(2)},'
            '${e.mood},'
            '${e.level},'
            '${e.email ?? ''}',
      ),
    ];
    return rows.join('\n');
  }

  // ---------- Private Helpers ----------

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) {
        entries.value = [];
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        entries.value = [];
        await prefs.remove(_kKey);
        return;
      }
      final list =
          decoded
              .whereType<Map<String, dynamic>>()
              .map(HistoryEntry.fromJson)
              .toList()
            ..sort((a, b) => a.ts.compareTo(b.ts));
      entries.value = list;
    } catch (_) {
      entries.value = [];
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kKey);
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final list = [...entries.value]..sort((a, b) => a.ts.compareTo(b.ts));
    await prefs.setString(
      _kKey,
      jsonEncode(list.map((x) => x.toJson()).toList()),
    );
  }

  void _mergeLocal(List<HistoryEntry> add) {
    final map = {for (final e in entries.value) e.docId: e};
    for (final e in add) {
      map[e.docId] = e;
    }
    final merged = map.values.toList()..sort((a, b) => a.ts.compareTo(b.ts));
    entries.value = merged;
  }

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('history');
  }

  void _wireFirestore(User? user) {
    _fsSub?.cancel();
    _fsSub = null;

    if (user == null) {
      // logged out: just keep local cache
      return;
    }

    _fsSub = _col(user.uid).orderBy('ts').snapshots().listen((snap) async {
      final cloud =
          snap.docs.map((d) => HistoryEntry.fromJson(d.data())).toList()
            ..sort((a, b) => a.ts.compareTo(b.ts));
      entries.value = cloud;
      await _saveLocal();
    });
  }
}
