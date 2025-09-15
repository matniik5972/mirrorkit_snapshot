import 'package:chef_ia_app/core/clock.dart';
import 'package:chef_ia_app/core/grace_policy.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ExpiryStatus { fresh, soon, expired, grace }

class PantryItem {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  String name;
  double? quantity;
  String? unit;
  String category;       // "Épicerie", "Frais", "Surgelé", "Boissons", "Autre"
  DateTime? expiry;      // DLC
  String? barcode;       // EAN
  final List<String> photos; // NEW: plusieurs photos
  final List<String> tags;   // NEW
  final String? note;        // NEW
  double? price;
  // Gestion récurrence & péremption
  bool recurring;        // produit racheté souvent (ex: yaourt)
  int?  graceDays;       // jours de tolérance après DLC
  DateTime? lastUpdate;  // dernière synchro/édition
  // Soft delete
  DateTime? deletedAt;   // null = actif, non-null = supprimé
  // NEW: Source tracking
  final String? source;     // ex: "chefia", "courses", "scan"
  final String? householdId; // null => local (appareil seul)
  final DateTime? expirationDate; // date de péremption (nullable)

  PantryItem copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    DateTime? expiry,
    String? barcode,
    List<String>? photos,
    List<String>? tags,
    String? note,
    double? price,
    bool? recurring,
    int? graceDays,
    DateTime? lastUpdate,
    DateTime? deletedAt,
    String? source,
    String? householdId,
    DateTime? expirationDate,
  }) {
    return PantryItem(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      expiry: expiry ?? this.expiry,
      barcode: barcode ?? this.barcode,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      price: price ?? this.price,
      recurring: recurring ?? this.recurring,
      graceDays: graceDays ?? this.graceDays,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      deletedAt: deletedAt ?? this.deletedAt,
      source: source ?? this.source,
      householdId: householdId ?? this.householdId,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }

  factory PantryItem.fromName(String name) => PantryItem(
    id: _uuid.v4(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    name: name,
  );

  PantryItem({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.quantity,
    this.unit,
    this.category = 'Autre',
    this.expiry,
    this.barcode,
    this.photos = const [],
    this.tags = const [],
    this.note,
    this.price,
    this.recurring = false,
    this.graceDays,
    this.lastUpdate,
    this.deletedAt,
    this.source,
    this.householdId,
    this.expirationDate,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      category: json['category'] as String? ?? 'Autre',
      expiry: json['expiry'] != null ? DateTime.parse(json['expiry'] as String) : null,
      barcode: json['barcode'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e as String).toList() ?? const [],
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? const [],
      note: json['note'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      recurring: json['recurring'] as bool? ?? false,
      graceDays: json['graceDays'] as int?,
      lastUpdate: json['lastUpdate'] != null ? DateTime.parse(json['lastUpdate'] as String) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      source: json['source'] as String?,
      householdId: json['householdId'] as String?,
      expirationDate: json['expirationDate'] != null ? DateTime.parse(json['expirationDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'expiry': expiry?.toIso8601String(),
      'barcode': barcode,
      'photos': photos,
      'tags': tags,
      'note': note,
      'price': price,
      'recurring': recurring,
      'graceDays': graceDays,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'source': source,
      'householdId': householdId,
      'expirationDate': expirationDate?.toIso8601String(),
      'schemaVersion': 3, // NEW: versionning avec soft delete
    };
  }

  /// Calcule le statut via Clock + GracePolicy (pas d'appel direct à DateTime.now()).
  ExpiryStatus statusWith(Clock clock, GracePolicy policy) {
    if (expiry == null) return ExpiryStatus.fresh;
    final now = clock.now();
    // déjà expiré → vérifier période de grâce
    if (expiry!.isBefore(now)) {
      final daysAfter = now.difference(expiry!).inDays;
      final grace = policy.graceFor(category);
      return daysAfter <= grace ? ExpiryStatus.grace : ExpiryStatus.expired;
    }
    final daysLeft = expiry!.difference(now).inDays;
    if (daysLeft <= 3) return ExpiryStatus.soon;
    return ExpiryStatus.fresh;
  }

  // Méthode pour créer un ID unique
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Vérifie si l'item est actif (non supprimé)
  bool get isActive => deletedAt == null;

  /// Marque l'item comme supprimé (soft delete)
  PantryItem markAsDeleted() {
    return copyWith(deletedAt: DateTime.now());
  }

  /// Restaure l'item (annule la suppression)
  PantryItem restore() {
    return copyWith(deletedAt: null);
  }


  // Méthodes de conversion pour compatibilité avec l'ancien modèle domain
  factory PantryItem.fromDomainModel(dynamic domainItem) {
    // Si c'est un PantryItem de domain/models/pantry_item.dart
    if (domainItem.runtimeType.toString().contains('PantryItem')) {
      try {
        final product = domainItem.product;
        return PantryItem(
          id: product.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: product.name,
          quantity: product.quantity,
          unit: product.unit,
          category: product.tags.isNotEmpty ? product.tags.first : 'Autre',
          expiry: domainItem.expiry,
          barcode: product.id,
          lastUpdate: DateTime.now(),
        );
      } catch (e) {
        // Fallback si la structure est différente
        return PantryItem(
          id: PantryItem.generateId(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          name: 'Produit importé',
          category: 'Autre',
          lastUpdate: DateTime.now(),
        );
      }
    }
    // Fallback par défaut
    return PantryItem(
      id: PantryItem.generateId(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Produit inconnu',
      category: 'Autre',
      lastUpdate: DateTime.now(),
    );
  }

  // Conversion vers l'ancien modèle domain (si nécessaire)
  Map<String, dynamic> toDomainModel() {
    return {
      'product': {
        'id': barcode ?? id,
        'name': name,
        'brand': null,
        'quantity': quantity,
        'unit': unit,
        'tags': [category],
      },
      'expiry': expiry?.toIso8601String(),
      'allergens': [],
      'ingredients': [],
      'stock': 1,
    };
  }

}
