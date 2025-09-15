// lib/agents/pantry_silent_agent.dart
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:chef_ia_app/core/event_bus.dart';
import 'package:chef_ia_app/core/events.dart';
import 'package:chef_ia_app/core/logging.dart';
import 'package:chef_ia_app/core/clock.dart';
import 'package:chef_ia_app/core/grace_policy.dart';
import 'package:chef_ia_app/agents/pantry_agent_cache.dart';
import 'package:chef_ia_app/models/pantry_item.dart';
import 'package:chef_ia_app/models/pantry_advisory.dart';
import 'package:chef_ia_app/services/ai/pantry_advisor_v2.dart';
import 'package:chef_ia_app/services/ai/local_pantry_advisor_v2.dart';
import 'package:chef_ia_app/services/ai/cloud_pantry_advisor_v2.dart';
import 'package:chef_ia_app/services/ai/cloud_client.dart';

typedef Json = Map<String, dynamic>;

class PantrySilentAgent {
  final EventBus _bus;
  final PantryAdvisor _local;
  final PantryAdvisor _cloud;
  final GracePolicy _grace;
  final PantryAgentCache _cache;
  final Clock _clock;
  final Duration cacheTtl;

  StreamSubscription<Json>? _sub;
  final List<PantryItem> _items = [];

  PantrySilentAgent({
    EventBus? bus,
    required PantryAdvisor local,
    required PantryAdvisor cloud,
    required GracePolicy grace,
    Clock clock = const SystemClock(),
    PantryAgentCache? cache,
    this.cacheTtl = const Duration(minutes: 5),
  })  : _bus = bus ?? EventBus(),
        _local = local,
        _cloud = cloud,
        _grace = grace,
        _cache = cache ?? PantryAgentCache(),
        _clock = clock;

  void start() {
    _sub ??= _bus.stream.listen(_onEvent);
    logEvent(module: 'agent.silent', event: 'started');
  }

  void stop() async {
    await _sub?.cancel();
    _sub = null;
    logEvent(module: 'agent.silent', event: 'stopped');
  }

  // Heuristique simple : si prefs.useCloud == true ET beaucoup d'items → cloud, sinon local
  bool _preferCloud(PantryUserPrefs prefs, int count) {
    if (!prefs.useCloud) return false;
    if (count >= 50) return true; // seuil simple ; ajustable
    return false;
  }

  void _onEvent(Json e) {
    try {
      final type = e['type'] as String? ?? '';
      final payload = (e['payload'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

      switch (type) {
        case 'pantry.item.added':
          _applyAdd(payload);
          break;
        case 'pantry.item.updated':
          _applyUpdate(payload);
          break;
        case 'pantry.item.deleted':
          _applyDelete(payload);
          break;
        case 'pantry.expiry.tick': // tick planifié (quotidien)
        case 'pantry.chat.requested': // demande implicite de conseils
          _recomputeAndPublish(payload);
          break;
        default:
          break;
      }
    } catch (err) {
      logEvent(module: 'agent.silent', event: 'event_error', level: 'ERROR', fields: {'error': err.toString()});
    }
  }

  void _applyAdd(Json p) {
    final it = _itemFromPayload(p);
    if (it == null) return;
    _items.removeWhere((x) => x.id == it.id);
    _items.add(it);
  }

  void _applyUpdate(Json p) => _applyAdd(p);

  void _applyDelete(Json p) {
    final id = p['id'] as String?;
    if (id == null) return;
    _items.removeWhere((x) => x.id == id);
  }

  PantryItem? _itemFromPayload(Json p) {
    try {
      // payload minimal : id, name?, category, expiry?, quantity?, unit?
      return PantryItem(
        id: p['id'] as String,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: p['name'] as String? ?? (p['barcode'] as String? ?? 'item'),
        category: p['category'] as String? ?? 'Autre',
        quantity: (p['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: p['unit'] as String? ?? 'pc',
        expiry: (p['expiry'] as String?) != null ? DateTime.tryParse(p['expiry'] as String) : null,
        barcode: p['barcode'] as String?,
        lastUpdate: DateTime.now(),
        photos: (p['photos'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        tags: (p['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        note: p['note'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  void _recomputeAndPublish(Json payload) {
    final prefs = _extractPrefs(payload);
    final ctxKey = _cache.makeKey({
      'count': _items.length,
      'useCloud': prefs.useCloud,
      'topK': prefs.topK,
      'grace': _grace.graceByCategory,
      // on pourrait inclure un hash des ids + expiries pour plus de précision
    });

    final cached = _cache.getIfFresh(ctxKey, ttl: cacheTtl);
    if (cached != null) {
      logEvent(module: 'agent.silent', event: 'cache_hit', fields: {'advisories': cached.advisories.length});
      _publishAdvisories(cached.advisories, fromCache: true);
      return;
    }

    final state = PantryState(items: List.unmodifiable(_items));
    final advisor = _preferCloud(prefs, _items.length) ? _cloud : _local;
    final t0 = DateTime.now();
    final result = advisor.advise(state, prefs); // sync by design (fallback géré côté cloud)
    final ms = DateTime.now().difference(t0).inMilliseconds;

    final asJson = result.map((a) => a.toJson()).toList();
    _cache.put(ctxKey, asJson);

    logEvent(module: 'agent.silent', event: 'advise_ready', fields: {
      'advisor': advisor == _cloud ? 'cloud' : 'local',
      'ms': ms,
      'items': _items.length,
      'advisories': result.length,
    });

    _publishAdvisories(asJson);
  }

  PantryUserPrefs _extractPrefs(Json payload) {
    // payload peut surcharger des prefs ponctuelles (ex: topK)
    final useCloud = (payload['useCloud'] as bool?) ?? true;
    final privacy = (payload['privacyCloud'] as bool?) ?? true;
    final topK = (payload['topK'] as int?) ?? 10;
    return PantryUserPrefs(useCloud: useCloud, privacyCloud: privacy, topK: topK);
  }

  void _publishAdvisories(List<Json> advisories, {bool fromCache = false}) {
    _bus.publish(PantryEvent(
      id: const Uuid().v4(),
      ts: DateTime.now(),
      type: 'pantry.advisory.ready',
      payload: {
        'fromCache': fromCache,
        'count': advisories.length,
        'advisories': advisories,
      },
      schemaVersion: 1,
    ).toJson());
  }
}
