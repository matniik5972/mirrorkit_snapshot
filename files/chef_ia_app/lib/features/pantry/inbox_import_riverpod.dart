import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inbox_import.dart'; // Utilise la classe ImportedPantryLine définie ici

/// Provider d'un callback d'upsert dans TON garde‑manger.
/// 👉 Branche ici ton repo/service réel (remplace le TODO).
final pantryUpsertFnProvider =
    Provider<Future<void> Function(ImportedPantryLine)>((ref) {
  return (line) async {
    // TODO: remplace par ton vrai upsert :
    // ex: await ref.read(pantryRepositoryProvider).upsert(line.toPantryItem());
  };
});

/// Consomme l'INBOX poussée par Courses (Broadcast+WorkManager côté Courses)
/// et appelle pantryUpsertFnProvider pour insérer/mettre à jour.
/// Retourne le nombre total de pièces importées.
Future<int> _importFromCoursesInbox(
    Future<void> Function(ImportedPantryLine) onUpsert) async {
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
          brand: it['brand'] as String?,
          unit: it['unit'] as String?,
          category: (it['category'] as String?) ?? 'Divers',
          qty: (it['qty'] as num?)?.toInt() ?? 1,
          unitPrice: (it['unitPrice'] as num?)?.toDouble(),
          origin: (it['origin'] as String?) ?? 'special',
        );
        await onUpsert(line);
        total += line.qty;
      }
    } catch (_) {
      // ignore / log si besoin
    }
  }
  await prefs.remove(inboxKey); // purge après import
  return total;
}

/// FutureProvider pour lancer l'import au boot (ou à la demande).
final coursesInboxConsumerProvider = FutureProvider<int>((ref) async {
  final upsert = ref.read(pantryUpsertFnProvider);
  final count = await _importFromCoursesInbox(upsert);
  return count;
});






