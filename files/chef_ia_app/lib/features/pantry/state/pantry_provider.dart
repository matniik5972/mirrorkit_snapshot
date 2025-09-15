import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chef_ia_app/features/pantry/state/pantry_state.dart';
import 'package:chef_ia_app/features/pantry/providers/pantry_prefs_provider.dart';
import 'package:chef_ia_app/services/storage/pantry_store.dart';
import 'package:chef_ia_app/models/pantry_item.dart';
import 'package:chef_ia_app/models/pantry_advisory.dart';
import 'package:chef_ia_app/features/pantry/advice/pantry_advisor_provider.dart';
import 'package:chef_ia_app/features/pantry/state/household_provider.dart';
import 'package:chef_ia_app/core/event_bus.dart';
import 'package:chef_ia_app/core/events.dart';

/// Fournit l'implémentation de persistance
final pantryStoreProvider = Provider<PantryStore?>((ref) {
  return PantryStore();
});

/// Notifier Riverpod pilotant l'état du garde-manger
class PantryNotifier extends StateNotifier<PantryState> {
  final PantryStore? store;
  late final _SaveDebouncer _debouncer;
  Timer? _searchDebouncer;

  PantryNotifier({this.store}) : super(const PantryState()) {
    _debouncer = _SaveDebouncer(store);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  // ---- Chargement / Persistance ------------------------------------------------
  Future<void> loadInitial() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // Mode solo par défaut (pas de foyer)
      final loaded = await store?.load() ?? <PantryItem>[];
      state = state.copyWith(allItems: loaded, isLoading: false);
      
      // Charger les préférences persistées
      await _loadPersistedPrefs();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> _loadPersistedPrefs() async {
    try {
      final prefs = ref.read(pantryPrefsProvider);
      final householdId = ref.read(householdProvider).id;
      
      final savedSort = await prefs.loadSort(householdId);
      final savedFilter = await prefs.loadFilter(householdId);
      
      if (savedSort != null) {
        // TODO: Implémenter setSort si nécessaire
        // ref.read(pantryFilterProvider.notifier).setSort(savedSort);
      }
      if (savedFilter != null) {
        // TODO: Implémenter setFilter si nécessaire
        // ref.read(pantryFilterProvider.notifier).setFilter(savedFilter);
      }
    } catch (e) {
      // Ignorer les erreurs de préférences
    }
  }

  // ---- CRUD Operations --------------------------------------------------------
  Future<void> addItem(PantryItem item) async {
    try {
      // Mode solo par défaut (pas de foyer)
      await store?.upsert(item);
      final updated = [...state.allItems, item];
      state = state.copyWith(allItems: updated);
      _debouncer.schedule(updated);
      EventBus().emit(PantryChanged({'action':'add','id': item.id}));
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateItem(PantryItem item) async {
    try {
      await store?.upsert(item);
      final updated = state.allItems.map((i) => i.id == item.id ? item : i).toList();
      state = state.copyWith(allItems: updated);
      _debouncer.schedule(updated);
      EventBus().emit('pantry.changed', {'action':'update','id': item.id});
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await store?.deleteItem(id);
      final updated = state.allItems.where((i) => i.id != id).toList();
      state = state.copyWith(allItems: updated);
      _debouncer.schedule(updated);
      EventBus().emit('pantry.changed', {'action':'remove','id': id});
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ---- Search & Filter --------------------------------------------------------
  void setSearchText(String text) {
    state = state.copyWith(searchText: text);
  }

  void setSearchTextDebounced(String text) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchText: text);
    });
  }

  void toggleFilter(String filter) {
    final filters = Set<String>.from(state.activeFilters);
    if (filters.contains(filter)) {
      filters.remove(filter);
    } else {
      filters.add(filter);
    }
    state = state.copyWith(activeFilters: filters);
  }

  // ---- Recalcul des conseils IA ----------------------------------------------
  Future<void> recomputeAdvisories() async {
    try {
      // Invalider le provider des conseils pour forcer le recalcul
      // Le pantryAdvisoryProvider se chargera du recalcul automatiquement
      // via l'écoute des changements d'items
      EventBus().emit('pantry.advisory.ready', {'count': state.allItems.length});
    } catch (e) {
      state = state.copyWith(error: 'Erreur recalcul conseils: $e');
    }
  }

  void applySmartFilter(String label) {
    // Impl. simple : si libellé contient "périm", on active un filtre interne
    final soon = label.toLowerCase().contains('périm');
    // TODO: Ajouter un champ activeFilterSoonExpired dans PantryState
    // state = state.copyWith(activeFilterSoonExpired: soon);
    // puis re-filtrer items visibles (ex: via un selector existant)
  }

  Future<void> handoffToChef(SimplePantryAdvisory a) async {
    final items = state.allItems; // adapte si tu as un selector d'items visibles
    final now = DateTime.now();
    final soon = items.where((it) =>
      it.expirationDate != null &&
      it.expirationDate!.isBefore(now.add(const Duration(days: 3)))
    ).toList();

    final payload = {
      'intent': 'chef.intent.cook',
      'from': 'pantry',
      'advisory': a.toJson(),
      'context': {
        'available': items.where((it) => (it.quantity ?? 1) > 0)
                          .map((e) => {'id': e.id, 'name': e.name, 'qty': e.quantity, 'exp': e.expirationDate?.toIso8601String()})
                          .toList(),
        'expiringSoon': soon.map((e) => e.id).toList(),
      },
    };

    // EventBus → l'agent Chef écoute et gère la génération de recettes
    EventBus().emit(ChefIntentCook(payload));
  }

  Future<void> handoffToCourses(SimplePantryAdvisory a) async {
    final items = state.allItems; // adapte si tu as un selector 'visible'
    final missing = items.where((it) => (it.quantity ?? 0) <= 0).map((e) => {
      'id': e.id, 'name': e.name, 'qty': e.quantity ?? 0,
      'exp': e.expirationDate?.toIso8601String(),
    }).toList();
    if (missing.isEmpty) return;

    final payload = {
      'intent': 'courses.intent.add',
      'from': 'pantry',
      'advisory': a.toJson(),
      'context': {'missing': missing},
    };

    // EventBus → l'autre agent écoute et gère l'ajout/mapping côté liste de courses
    EventBus().emit(CoursesIntentAdd(payload));
  }

  void navigateForAdvisory(SimplePantryAdvisory a) {
    // stub: navigation interne (catégories, etc.)
    // TODO: Navigation interne
  }

  // ---- Gestion des erreurs ---------------------------------------------------
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ---- Méthodes manquantes pour compatibilité ---------------------------------
  void add(VoidCallback callback) {
    // TODO: Implémenter l'ajout d'item
    callback();
  }

  void scan(VoidCallback callback) {
    // TODO: Implémenter le scan de code-barres
    callback();
  }

  void openItem(PantryItem item, Function(PantryItem) callback) {
    // TODO: Implémenter l'ouverture d'item
    callback(item);
  }

  void showItemMenu(PantryItem item, Function(PantryItem) callback) {
    // TODO: Implémenter le menu d'item
    callback(item);
  }

  void removeItem(String id) {
    deleteItem(id);
  }

  void clearFilters() {
    state = state.copyWith(activeFilters: const {});
  }
}

/// Provider du notifier
final pantryNotifierProvider = StateNotifierProvider<PantryNotifier, PantryState>((ref) {
  final store = ref.watch(pantryStoreProvider);
  return PantryNotifier(store: store);
});

/// Provider des items visibles
final pantryVisibleItemsProvider = Provider<List<PantryItem>>((ref) {
  final state = ref.watch(pantryNotifierProvider);
  return state.visibleItems;
});

/// Provider des IDs visibles
final pantryVisibleIdsProvider = Provider<List<String>>((ref) {
  final items = ref.watch(pantryVisibleItemsProvider);
  return items.map((item) => item.id).toList();
});

/// Provider d'un item par ID
final pantryItemByIdProvider = Provider.family<PantryItem?, String>((ref, id) {
  final items = ref.watch(pantryVisibleItemsProvider);
  try {
    return items.firstWhere((item) => item.id == id);
  } catch (e) {
    return null;
  }
});

/// Sélecteurs granulaires pour les propriétés spécifiques d'un item
final pantryItemNameProvider = Provider.family<String, String>((ref, id) {
  final item = ref.watch(pantryItemByIdProvider(id));
  return item?.name ?? '';
});

final pantryItemQuantityProvider = Provider.family<double?, String>((ref, id) {
  final item = ref.watch(pantryItemByIdProvider(id));
  return item?.quantity;
});

final pantryItemExpiryProvider = Provider.family<DateTime?, String>((ref, id) {
  final item = ref.watch(pantryItemByIdProvider(id));
  return item?.expiry;
});

final pantryItemCategoryProvider = Provider.family<String, String>((ref, id) {
  final item = ref.watch(pantryItemByIdProvider(id));
  return item?.category ?? 'Autre';
});

/// Provider du texte de recherche
final pantrySearchTextProvider = Provider<String>((ref) {
  final state = ref.watch(pantryNotifierProvider);
  return state.searchText;
});

/// Provider des filtres actifs
final pantryActiveFiltersProvider = Provider<Set<String>>((ref) {
  final state = ref.watch(pantryNotifierProvider);
  return state.activeFilters;
});

/// Provider du nombre total d'items
final pantryTotalCountProvider = Provider<int>((ref) {
  final state = ref.watch(pantryNotifierProvider);
  return state.allItems.length;
});

/// Debouncer pour les sauvegardes
class _SaveDebouncer {
  _SaveDebouncer(this._store);
  final PantryStore? _store;
  Timer? _t;
  
  void schedule(List<PantryItem> items) {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 500), () async {
      if (_store != null) {
        await _store?.save(items);
      }
    });
  }
  
  void dispose() => _t?.cancel();
}
