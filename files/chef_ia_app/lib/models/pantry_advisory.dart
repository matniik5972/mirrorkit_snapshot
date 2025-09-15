enum AdvisoryType { expireSoon, grace, restock, suggestion }

// Modèle simple pour les conseils de base
class SimplePantryAdvisory {
  final String type;   // ex: 'FILTER' | 'HANDOFF_CHEF' | 'NAVIGATE'
  final String label;  // ex: 'Bientôt périmés', 'Cuisiner: Riz au lait'
  final double? confidence; // 0..1
  final String? source;     // 'local' | 'cloud'
  final String? targetAgent; // 'chef' | 'courses' | ...

  const SimplePantryAdvisory({
    required this.type,
    required this.label,
    this.confidence,
    this.source,
    this.targetAgent,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'label': label,
    'confidence': confidence,
    'source': source,
    'targetAgent': targetAgent,
  };

  factory SimplePantryAdvisory.fromJson(Map<String, dynamic> j) => SimplePantryAdvisory(
    type: j['type'] as String,
    label: j['label'] as String,
    confidence: (j['confidence'] as num?)?.toDouble(),
    source: j['source'] as String?,
    targetAgent: j['targetAgent'] as String?,
  );
}

class PantryAdvisoryAction {
  final String action; // e.g. "FILTER","RECIPE","NAVIGATE"
  final Map<String, dynamic> params;
  const PantryAdvisoryAction(this.action, [this.params = const {}]);
  Map<String, dynamic> toJson() => {'action': action, 'params': params};
  factory PantryAdvisoryAction.fromJson(Map<String, dynamic> j) =>
      PantryAdvisoryAction(j['action'] as String, (j['params'] as Map?)?.cast<String, dynamic>() ?? {});
}

class PantryAdvisory {
  final String id;                // unique (ex: type+itemId+date)
  final AdvisoryType type;
  final String title;             // ex: "À consommer bientôt"
  final String body;              // max 3 lignes pour la bulle
  final String? reason; // NEW: explication courte
  final List<String> itemIds;     // items concernés
  final DateTime createdAt;
  final int priority;             // 1=critique, 2=important, 3=info
  final DateTime? notifyAt;       // quand pousser une notif locale (option)
  final List<PantryAdvisoryAction> actions; // NEW: CTAs
  final double? confidence;       // 0..1 pour scoring
  final String? source;           // 'local' | 'cloud'

  const PantryAdvisory({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.reason,
    required this.itemIds,
    required this.createdAt,
    this.priority = 2,
    this.notifyAt,
    this.actions = const [],
    this.confidence,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'reason': reason,
    'itemIds': itemIds,
    'priority': priority,
    'type': type.name,
    'actions': actions.map((a) => a.toJson()).toList(),
    'confidence': confidence,
    'source': source,
    'schemaVersion': 2,
  };

  factory PantryAdvisory.fromJson(Map<String, dynamic> j) => PantryAdvisory(
    id: j['id'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    reason: j['reason'] as String?,
    itemIds: (j['itemIds'] as List).map((e) => e as String).toList(),
    priority: j['priority'] as int,
    type: AdvisoryType.values.firstWhere((e) => e.name == j['type']),
    actions: (j['actions'] as List?)
        ?.map((e) => PantryAdvisoryAction.fromJson((e as Map).cast<String, dynamic>()))
        .toList() ?? const [],
    createdAt: DateTime.parse(j['createdAt'] as String),
    notifyAt: j['notifyAt'] != null ? DateTime.parse(j['notifyAt'] as String) : null,
    confidence: (j['confidence'] as num?)?.toDouble(),
    source: j['source'] as String?,
  );
}



