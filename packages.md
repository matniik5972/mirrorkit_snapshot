# Snapshot – packages – 2025-09-15T23:19:24
**Snapshot-Of:** `6482085b719a5dd2e6e053ebcd5c4b3ae03bd177`
**Generated:** 2025-09-15T23:19:24
**Files:** 3

## Index
- `packages/shared_models/pubspec.yaml` — [RAW](https://raw.githubusercontent.com/matniik5972/mirrorkit_snapshot/main/files/packages/shared_models/pubspec.yaml)
- `packages/shared_models/lib/src/product.dart` — [RAW](https://raw.githubusercontent.com/matniik5972/mirrorkit_snapshot/main/files/packages/shared_models/lib/src/product.dart)
- `packages/shared_models/lib/src/shopping_item.dart` — [RAW](https://raw.githubusercontent.com/matniik5972/mirrorkit_snapshot/main/files/packages/shared_models/lib/src/shopping_item.dart)

---
## Fichiers

### packages/shared_models/pubspec.yaml
```yaml
name: shared_models
description: Shared domain models for ChefIA & Courses (no persistence)
version: 0.1.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  collection: ^1.18.0
dev_dependencies:
  lints: ^3.0.0
  test: ^1.25.0





```

### packages/shared_models/lib/src/product.dart
```dart
class Product {
  final String id;          // stable id (barcode or internal)
  final String name;
  final String? brand;
  final String? unit;       // ex: "g", "ml", "pcs"
  final double? size;       // ex: 500 (ml)
  final String? category;   // ex: "Fruits", "Dairy"

  const Product({
    required this.id,
    required this.name,
    this.brand,
    this.unit,
    this.size,
    this.category,
  });

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? unit,
    double? size,
    String? category,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    unit: unit ?? this.unit,
    size: size ?? this.size,
    category: category ?? this.category,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'unit': unit,
    'size': size,
    'category': category,
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    name: j['name'] as String,
    brand: j['brand'] as String?,
    unit: j['unit'] as String?,
    size: (j['size'] as num?)?.toDouble(),
    category: j['category'] as String?,
  );
}





```

### packages/shared_models/lib/src/shopping_item.dart
```dart
class ShoppingItemDto {
  final String id;        // chaîne stable (peut être un uuid)
  final String name;
  final int quantity;
  final bool done;
  final String? pantryLinkBarcode;

  const ShoppingItemDto({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.done = false,
    this.pantryLinkBarcode,
  });

  ShoppingItemDto copyWith({
    String? id,
    String? name,
    int? quantity,
    bool? done,
    String? pantryLinkBarcode,
  }) => ShoppingItemDto(
        id: id ?? this.id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        done: done ?? this.done,
        pantryLinkBarcode: pantryLinkBarcode ?? this.pantryLinkBarcode,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'done': done,
    'pantryLinkBarcode': pantryLinkBarcode,
  };

  factory ShoppingItemDto.fromJson(Map<String, dynamic> j) => ShoppingItemDto(
    id: j['id'] as String,
    name: j['name'] as String,
    quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    done: j['done'] as bool? ?? false,
    pantryLinkBarcode: j['pantryLinkBarcode'] as String?,
  );
}





```
