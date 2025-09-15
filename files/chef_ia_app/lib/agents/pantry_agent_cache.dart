// lib/agents/pantry_agent_cache.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AdvisoryCacheEntry {
  final String key; // hash du contexte
  final DateTime ts;
  final List<Map<String, dynamic>> advisories; // JSON sérialisable
  const AdvisoryCacheEntry({required this.key, required this.ts, required this.advisories});
  bool isFresh(Duration ttl) => DateTime.now().difference(ts) <= ttl;
}

class PantryAgentCache {
  AdvisoryCacheEntry? _last;

  String makeKey(Map<String, Object?> ctx) {
    final s = jsonEncode(ctx);
    return sha256.convert(utf8.encode(s)).toString();
  }

  AdvisoryCacheEntry? getIfFresh(String key, {Duration ttl = const Duration(minutes: 5)}) {
    final e = _last;
    if (e == null) return null;
    if (e.key != key) return null;
    return e.isFresh(ttl) ? e : null;
  }

  void put(String key, List<Map<String, dynamic>> advisories) {
    _last = AdvisoryCacheEntry(key: key, ts: DateTime.now(), advisories: advisories);
  }
}











