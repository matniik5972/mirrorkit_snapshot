import 'package:flutter/foundation.dart';
// ⚠️ Adapte le chemin d'import selon ton projet.
import 'package:chef_ia_app/models/pantry_item.dart';

@immutable
class PantryState {
  final List<PantryItem> allItems;
  final String searchText;
  final Set<String> activeFilters;
  final bool isLoading;
  final String? error;

  const PantryState({
    this.allItems = const [],
    this.searchText = '',
    this.activeFilters = const {},
    this.isLoading = false,
    this.error,
  });

  PantryState copyWith({
    List<PantryItem>? allItems,
    String? searchText,
    Set<String>? activeFilters,
    bool? isLoading,
    String? error,
  }) {
    return PantryState(
      allItems: allItems ?? this.allItems,
      searchText: searchText ?? this.searchText,
      activeFilters: activeFilters ?? this.activeFilters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Items filtrés + recherche (exemple simple, adapte la logique à ton besoin)
  List<PantryItem> get visibleItems {
    Iterable<PantryItem> items = allItems;

    if (activeFilters.isNotEmpty) {
      items = items.where((it) {
        // EXEMPLE : on filtre par tags/catégorie s'ils existent
        final tags = it.tags;
        return activeFilters.any(tags.contains);
      });
    }

    final q = searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((it) =>
          it.name.toLowerCase().contains(q) ||
          it.category.toLowerCase().contains(q));
    }

    return items.toList(growable: false);
  }
}
