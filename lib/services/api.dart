import 'dart:convert';
import 'package:http/http.dart' as http;

/// When testing on the same machine: keep localhost.
/// If testing on a phone/tablet, replace with your computer's LAN IP, e.g. "http://192.168.1.23:8000"
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://127.0.0.1:8000',
);

class PredictResponse {
  final int stressLevel; // 0 low, 1 med, 2 high
  final String label;    // "Low"/"Medium"/"High"
  final String emoji;
  final double confidence;
  final Map<String, dynamic> drivers;
  final String tip;

  PredictResponse({
    required this.stressLevel,
    required this.label,
    required this.emoji,
    required this.confidence,
    required this.drivers,
    required this.tip,
  });

  factory PredictResponse.fromJson(Map<String, dynamic> j) => PredictResponse(
    stressLevel: j['stress_level'] as int,
    label: j['label'] as String,
    emoji: j['emoji'] as String,
    confidence: (j['confidence'] as num).toDouble(),
    drivers: (j['drivers'] as Map).map((k, v) => MapEntry(k.toString(), v)),
    tip: j['tip'] as String,
  );
}

class Api {
  static Future<PredictResponse> predict({
    required double hoursStudied,
    required double sleepHours,
    required String mood, // "sad" | "neutral" | "happy"
  }) async {
    final uri = Uri.parse('$kApiBase/predict');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hours_studied': hoursStudied,
        'sleep_hours': sleepHours,
        'mood': mood,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return PredictResponse.fromJson(jsonDecode(res.body));
    }
    throw Exception('Server error ${res.statusCode}: ${res.body}');
  }
}
