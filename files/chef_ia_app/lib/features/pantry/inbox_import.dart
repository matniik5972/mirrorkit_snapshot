import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Représente une ligne importée depuis Courses
class ImportedPantryLine {
  final String id;
  final String name;
  final String? brand;
  final String? unit;
  final String category;
  final int qty;
  final double? unitPrice;
  final String origin; // "recipe" | "main" | "special"

  ImportedPantryLine({
    required this.id,
    required this.name,
    this.brand,
    this.unit,
    required this.category,
    required this.qty,
    this.unitPrice,
    required this.origin,
  });
}

/// Consomme l'INBOX poussée par Courses (Broadcast + WorkManager côté Courses)
/// et te laisse gérer l'insertion via [onUpsert].
///
/// Retourne le nombre total de pièces importées (somme des qty).
Future<int> importFromCoursesInbox({
  required Future<void> Function(ImportedPantryLine line) onUpsert,
}) async {
  const inboxKey = 'inbox_from_courses_v1';
  final prefs = await SharedPreferences.getInstance();
  final set = prefs.getStringList(inboxKey) ?? [];

  if (set.isEmpty) return 0;

  var total = 0;

  for (final raw in set) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = (map['items'] as List).cast<Map<String, dynamic>>();

      for (final it in items) {
        final line = ImportedPantryLine(
          id: (it['id'] ?? '').toString(),
          name: (it['name'] ?? '').toString(),
          brand: (it['brand'] as String?),
          unit: (it['unit'] as String?),
          category: (it['category'] as String?) ?? 'Divers',
          qty: (it['qty'] as num?)?.toInt() ?? 1,
          unitPrice: (it['unitPrice'] as num?)?.toDouble(),
          origin: (it['origin'] as String?) ?? 'special',
        );

        // Laisse l'app appelante décider comment stocker/merger
        await onUpsert(line);
        total += line.qty;
      }
    } catch (_) {
      // ignore / log si besoin
    }
  }

  // Purge de l'INBOX une fois consommée
  await prefs.remove(inboxKey);
  return total;
}






