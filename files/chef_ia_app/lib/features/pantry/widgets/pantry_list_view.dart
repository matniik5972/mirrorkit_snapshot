import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chef_ia_app/features/pantry/state/pantry_provider.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_item_tile.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_smart_empty_state.dart';
import 'package:chef_ia_app/models/pantry_item.dart';

class PantryListView extends ConsumerWidget {
  const PantryListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(pantryVisibleIdsProvider);
    
    // Récupérer les items via les IDs
    final items = ids.map((id) => ref.watch(pantryItemByIdProvider(id))).where((item) => item != null).cast<PantryItem>().toList();
    
    // Tri par date de péremption ascendante (fallback: alpha)
    final sortedItems = List<PantryItem>.from(items);
    sortedItems.sort((a, b) {
      final da = a.expirationDate;
      final db = b.expirationDate;
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1; // ceux avec date en premier
      if (db != null) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    // Empty state intelligent
    if (sortedItems.isEmpty) {
      return PantrySmartEmptyState(
        onScan: () {
          // TODO: Implémenter le scan
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scan - À implémenter')),
          );
        },
        onManual: () {
          // TODO: Implémenter la saisie manuelle
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saisie manuelle - À implémenter')),
          );
        },
        onImport: () {
          // TODO: Implémenter l'import
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import - À implémenter')),
          );
        },
      );
    }

    return ListView.builder(
      key: const Key('pantry_list_view'),
      itemCount: sortedItems.length,
      prototypeItem: const PantryItemTile(
        title: 'Prototype Item',
        subtitle: 'Prototype subtitle',
      ),
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        return PantryItemTile(
          key: ValueKey(item.id), // Optimisation: ValueKey pour éviter les rebuilds
          item: item,
          leading: _categoryIcon(item.category),
          title: item.name,
          subtitle: [
            if (item.quantity != null) '${item.quantity}',
            if (item.expiry != null) '• ${item.expiry}',
          ].where((s) => s.isNotEmpty).join(' ').isEmpty
              ? null
              : [
                  if (item.quantity != null) '${item.quantity}',
                  if (item.expiry != null) '• ${item.expiry}',
                ].join(' '),
          trailing: _itemActions(context, ref, item.id),
          onTap: () => ref.read(pantryNotifierProvider.notifier).openItem(item, (it) {
            // ton _openItem(it) si tu veux garder la navigation existante
          }),
          onLongPress: () => ref.read(pantryNotifierProvider.notifier).showItemMenu(item, (it) {
            // ton _showContextMenu(it) si besoin
          }),
        );
      },
    );
  }

  Widget _categoryIcon(String? cat) => const Icon(Icons.inventory_2_outlined);

  Widget _itemActions(BuildContext ctx, WidgetRef ref, String id) {
    // Place ton trailing/menu bouton ici si tu veux le standardiser
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'delete') {
          ref.read(pantryNotifierProvider.notifier).removeItem(id);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'delete', child: Text('Supprimer')),
      ],
    );
  }
}

