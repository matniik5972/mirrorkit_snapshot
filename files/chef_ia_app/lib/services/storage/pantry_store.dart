import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chef_ia_app/core/event_bus.dart';
import 'package:chef_ia_app/core/events.dart';
import 'package:uuid/uuid.dart';
import '../../models/pantry_item.dart';

class PantryStore {
  static const _kKeyV2 = 'pantry_items_v2';
  static const _kKeyV1 = 'pantry_items'; // fallback éventuel
  static const _kSchemaKey = 'pantry_schema_version';

  // Coalescing des événements pour éviter les rebuild storms
  Timer? _emitTimer;
  bool _emitPending = false;
  
  // Cache mémoire pour fallback si SP échoue
  List<PantryItem>? _inMemoryCache;
  
  void _emitCoalesced() {
    if (_emitTimer != null) { 
      _emitPending = true; 
      return; 
    }
    _emitTimer = Timer(const Duration(milliseconds: 16), () {
      _emitTimer = null;
      EventBus().publish({'type': AppEvents.pantryItemsChanged});
      if (_emitPending) { 
        _emitPending = false; 
        _emitCoalesced(); 
      }
    });
  }

  String _normalizeName(String s) {
    final trimmed = s.toLowerCase().trim();
    if (trimmed.isEmpty) return '';
    
    // Normalisation des accents (NFD + suppression des diacritiques)
    final noDiacritics = trimmed
        .replaceAll('à', 'a').replaceAll('á', 'a').replaceAll('â', 'a').replaceAll('ã', 'a').replaceAll('ä', 'a')
        .replaceAll('è', 'e').replaceAll('é', 'e').replaceAll('ê', 'e').replaceAll('ë', 'e')
        .replaceAll('ì', 'i').replaceAll('í', 'i').replaceAll('î', 'i').replaceAll('ï', 'i')
        .replaceAll('ò', 'o').replaceAll('ó', 'o').replaceAll('ô', 'o').replaceAll('õ', 'o').replaceAll('ö', 'o')
        .replaceAll('ù', 'u').replaceAll('ú', 'u').replaceAll('û', 'u').replaceAll('ü', 'u')
        .replaceAll('ç', 'c').replaceAll('ñ', 'n');
    
    // Suppression des caractères non-alphanumériques + espaces multiples
    return noDiacritics
        .replaceAll(RegExp(r"[^a-z0-9 ]", caseSensitive: false), ' ')
        .replaceAll(RegExp(r"\s+"), ' ')
        .trim();
  }

  bool _isLikelyDuplicate(PantryItem a, PantryItem b) {
    final na = _normalizeName(a.name);
    final nb = _normalizeName(b.name);
    if (na == nb) return true;
    // Égalité stricte uniquement pour éviter les faux positifs
    return false; // Exiger égalité stricte du nom normalisé
  }

  Future<List<PantryItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKeyV2) ?? prefs.getString(_kKeyV1);
      if (raw == null || raw.isEmpty) return _inMemoryCache ?? [];
      
      final items = _decodeSafe(raw);
      // Filtrer les items actifs (non supprimés)
      final activeItems = items.where((item) => item.isActive).toList();
      _inMemoryCache = activeItems;
      return activeItems;
    } catch (e, st) {
      if (kDebugMode) {
        print('PantryStore: load() error: $e');
      }
      return _inMemoryCache ?? [];
    }
  }

  /// Décodage JSON tolérant (ne crash pas sur JSON partiel)
  List<PantryItem> _decodeSafe(String raw) {
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map((m) => PantryItem.fromJson(m)).toList();
    } catch (_) {
      // Tentative de récupération minimale
      try {
        final dynamic parsed = jsonDecode(raw);
        if (parsed is List) {
          return parsed.map((e) {
            try { 
              return PantryItem.fromJson(e as Map<String, dynamic>); 
            } catch (_) { 
              return null; 
            }
          }).whereType<PantryItem>().toList(growable: false);
        }
      } catch (_) {
        // JSON complètement corrompu
      }
      return [];
    }
  }

  Future<List<PantryItem>> loadByHousehold(String householdId) async {
    final all = await load();
    return all.where((e) => e.householdId == householdId).toList();
  }

  /// Charge tous les items (y compris supprimés) pour l'export
  Future<List<PantryItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKeyV2) ?? prefs.getString(_kKeyV1);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map((m) => PantryItem.fromJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<PantryItem> items) async {
    final data = items.map((e) => e.toJson()).toList();
    final jsonStr = jsonEncode(data);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setString(_kKeyV2, jsonStr);
      if (!ok) {
        if (kDebugMode) {
          print('PantryStore: SharedPreferences write failed, keeping process cache');
        }
        _inMemoryCache = items; // fallback
      } else {
        _inMemoryCache = items;
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('PantryStore: save() error → fallback memory: $e');
      }
      _inMemoryCache = items;
    }
  }

  Future<void> saveAllItems(List<PantryItem> items, {required int schemaVersion}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = items.map((e) => e.toJson()).toList();
    await prefs.setString(_kKeyV2, jsonEncode(data));
    await prefs.setInt(_kSchemaKey, schemaVersion);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKeyV2);
  }

  Future<void> upsert(PantryItem incoming) async {
    final now = DateTime.now();
    final inc = incoming.copyWith(updatedAt: now);
    final all = await load();

    // 1) match par id
    final idx = all.indexWhere((e) => e.id == inc.id);
    if (idx >= 0) {
      if (inc.updatedAt.isAfter(all[idx].updatedAt)) {
        all[idx] = inc; // plus récent l'emporte
      }
      await _save(all);
      _emitCoalesced();
      return;
    }

    // 2) dédup par nom normalisé
    final dupIdx = all.indexWhere((e) => _isLikelyDuplicate(e, inc));
    if (dupIdx >= 0) {
      // stratégie: garder l'id existant, fusionner les champs utiles
      final base = all[dupIdx];
      all[dupIdx] = base.copyWith(
        name: base.name.length >= inc.name.length ? base.name : inc.name,
        updatedAt: now.isAfter(base.updatedAt) ? now : base.updatedAt,
        // ajoutez ici d'éventuelles fusions de quantité/catégorie
      );
      await _save(all);
      _emitCoalesced();
      return;
    }

    // 3) nouvel item
    all.add(inc);
    await _save(all);
    EventBus().publish({'type':'pantry.storage.upserted','payload':{'id': inc.id}});
  }

  Future<void> _save(List<PantryItem> items) async {
    await save(items);
  }

  /// Upsert local sans I/O (pour batch processing)
  void _upsertLocal(List<PantryItem> items, PantryItem incoming) {
    final now = DateTime.now();
    final inc = incoming.copyWith(updatedAt: now);

    // 1) match par id
    final idx = items.indexWhere((e) => e.id == inc.id);
    if (idx >= 0) {
      if (inc.updatedAt.isAfter(items[idx].updatedAt)) {
        items[idx] = inc; // plus récent l'emporte
      }
      return;
    }

    // 2) dédup par nom normalisé
    final dupIdx = items.indexWhere((e) => _isLikelyDuplicate(e, inc));
    if (dupIdx >= 0) {
      final base = items[dupIdx];
      items[dupIdx] = base.copyWith(
        name: base.name.length >= inc.name.length ? base.name : inc.name,
        updatedAt: now.isAfter(base.updatedAt) ? now : base.updatedAt,
      );
      return;
    }

    // 3) nouvel item
    items.add(inc);
  }

  Future<void> addItem(PantryItem item) async {
    await upsert(item);
    
    _emitCoalesced();
  }

  Future<void> updateItem(PantryItem item) async {
    await upsert(item);
    
    _emitCoalesced();
  }

  Future<void> deleteItem(String id, {bool soft = true}) async {
    if (soft) {
      // Soft delete : marque comme supprimé
      final allItems = await loadAll();
      final updatedItems = allItems.map((item) {
        if (item.id == id) {
          return item.markAsDeleted();
        }
        return item;
      }).toList();
      await save(updatedItems); // Sauvegarde l'état mis à jour (soft-deleted)
      
      _emitCoalesced();
    } else {
      // Hard delete : supprime définitivement
      final allItems = await loadAll();
      allItems.removeWhere((i) => i.id == id);
      await save(allItems);
      
      _emitCoalesced();
    }
  }

  /// Restaure un item supprimé
  Future<bool> restoreItem(String id) async {
    try {
      final allItems = await loadAll();
      final itemToRestore = allItems.firstWhere(
        (item) => item.id == id,
        orElse: () => PantryItem.fromName(''), // Item vide si non trouvé
      );
      
      if (itemToRestore.name.isEmpty) {
        // Item non trouvé (peut-être purgé)
        return false;
      }
      
      final updatedItems = allItems.map((item) {
        if (item.id == id) {
          return item.restore();
        }
        return item;
      }).toList();
      await save(updatedItems);
      
      _emitCoalesced();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('PantryStore: restoreItem() error: $e');
      }
      return false;
    }
  }

  /// Purge les items supprimés depuis plus de 30 jours
  Future<void> purgeDeletedItems({int daysOld = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final allItems = await loadAll();
    final activeItems = allItems.where((item) {
      if (item.deletedAt == null) return true; // Item actif
      return item.deletedAt!.isAfter(cutoff); // Item supprimé récemment
    }).toList();
    
    if (activeItems.length != allItems.length) {
      await save(activeItems);
      _emitCoalesced();
      
      // Métriques debug
      assert(() {
        if (kDebugMode) {
          print('PantryStore purge: removed ${allItems.length - activeItems.length} items');
        }
        return true;
      }());
    }
  }

  /// Exporte tous les items (actifs + supprimés) en JSON
  Future<String> exportAsJson() async {
    final allItems = await loadAll();
    final export = {
      'schemaVersion': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': allItems.map((item) => item.toJson()).toList(),
    };
    return jsonEncode(export);
  }

  /// Importe des items depuis un JSON avec déduplication
  Future<Map<String, int>> importFromJson(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final importedItems = (data['items'] as List)
          .map((m) => PantryItem.fromJson(m.cast<String, dynamic>()))
          .toList();
      
      final existingItems = await loadAll();
      final existingIds = existingItems.map((e) => e.id).toSet();
      final existingBarcodes = existingItems
          .where((e) => e.barcode != null)
          .map((e) => e.barcode!)
          .toSet();
      
      int added = 0;
      int updated = 0;
      int skipped = 0;
      
      // Batch processing : éviter N writes
      final updatedState = List<PantryItem>.from(existingItems);
      
      for (final item in importedItems) {
        final isDup = existingIds.contains(item.id) ||
                     (item.barcode != null && existingBarcodes.contains(item.barcode!));
        if (isDup) { 
          updated++; 
        } else { 
          added++; 
        }
        _upsertLocal(updatedState, item);
      }
      
      // Un seul write pour tous les items
      await save(updatedState);
      
      _emitCoalesced();
      
      // Métriques debug
      assert(() {
        if (kDebugMode) {
          print('PantryStore import: added=$added updated=$updated skipped=$skipped');
        }
        return true;
      }());
      
      return {'added': added, 'updated': updated, 'skipped': skipped};
    } catch (e) {
      throw Exception('Erreur lors de l\'import: $e');
    }
  }
}




