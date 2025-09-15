// lib/core/events.dart

/// Clés d'événements centralisées pour éviter les typos
abstract class AppEvents {
  static const pantryItemsChanged = 'pantry.items.changed';
  static const pantryItemAdded = 'pantry.item.added';
  static const pantryItemUpdated = 'pantry.item.updated';
  static const pantryItemDeleted = 'pantry.item.deleted';
  static const pantryItemRestored = 'pantry.item.restored';
  static const pantryItemsPurged = 'pantry.items.purged';
  static const pantryItemsImported = 'pantry.items.imported';
  static const pantryStorageUpserted = 'pantry.storage.upserted';
}

class PantryEvent {
  final String id; // uuid
  final DateTime ts;
  final String type; // e.g. pantry.item.updated
  final Map<String, dynamic> payload; // JSON stable versionné
  final int schemaVersion;

  PantryEvent({
    required this.id,
    required this.ts,
    required this.type,
    required this.payload,
    this.schemaVersion = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ts': ts.toIso8601String(),
    'type': type,
    'schemaVersion': schemaVersion,
    'payload': payload,
  };
}

// ============================================================
// LEGACY EVENT MODEL (compat old tips_engine / runner)
// ============================================================
abstract class AppEvent {
  final String type;
  final Map<String, dynamic> payload;
  const AppEvent(this.type, this.payload);

  // helpers communs (accès style .message dans l'ancien code)
  String? get message => payload['message'] as String?;
  String? get stepId  => payload['stepId'] as String?;
  String? get risk    => payload['risk'] as String?;
}

class StepStarted extends AppEvent {
  StepStarted(String stepId) : super('step.started', {'stepId': stepId});
}

class RiskDetected extends AppEvent {
  RiskDetected(String stepId, String risk)
      : super('risk.detected', {'stepId': stepId, 'risk': risk});
}

class TipsRequested extends AppEvent {
  TipsRequested(String stepId, String question)
      : super('tips.requested', {'stepId': stepId, 'question': question});
  String? get question => payload['question'] as String?;
}

class TipsPushed extends AppEvent {
  TipsPushed(String stepId, String message)
      : super('tips.pushed', {'stepId': stepId, 'message': message});
}

class AdviceEvent extends AppEvent {
  AdviceEvent(String message) : super('advice.event', {'message': message});
}

// Événements typés (compat unifiée)
class PantryChanged extends AppEvent {
  PantryChanged(Map<String, dynamic> payload) : super('pantry.changed', payload);
}
class PantryAdvisoryReady extends AppEvent {
  PantryAdvisoryReady(Map<String, dynamic> payload) : super('pantry.advisory.ready', payload);
}
class ChefIntentCook extends AppEvent {
  ChefIntentCook(Map<String, dynamic> payload) : super('chef.intent.cook', payload);
}
class CoursesIntentAdd extends AppEvent {
  CoursesIntentAdd(Map<String, dynamic> payload) : super('courses.intent.add', payload);
}

/// Conversion Map -> AppEvent (pour EventBus.on('type'))
AppEvent? appEventFrom(Map<String, dynamic> e) {
  final t = e['type'] as String? ?? '';
  final p = (e['payload'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
  switch (t) {
    case 'step.started':
      final id = p['stepId'] as String?;
      return id == null ? null : StepStarted(id);
    case 'risk.detected':
      final id = p['stepId'] as String?;
      final r  = p['risk'] as String?;
      return (id == null || r == null) ? null : RiskDetected(id, r);
    case 'tips.requested':
      final id = p['stepId'] as String?;
      final q  = p['question'] as String?;
      return (id == null || q == null) ? null : TipsRequested(id, q);
    case 'tips.pushed':
      final id = p['stepId'] as String?;
      final m  = p['message'] as String?;
      return (id == null || m == null) ? null : TipsPushed(id, m);
    case 'advice.event':
      final m = p['message'] as String?;
      return m == null ? null : AdviceEvent(m);
    case 'pantry.changed': return PantryChanged(p);
    case 'pantry.advisory.ready': return PantryAdvisoryReady(p);
    case 'chef.intent.cook': return ChefIntentCook(p);
    case 'courses.intent.add': return CoursesIntentAdd(p);
  }
  return null;
}
