import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:chef_ia_app/features/pantry/state/pantry_provider.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_filters_bar.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_empty_state.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_advisory_banner.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_list_view.dart';
import 'package:chef_ia_app/models/pantry_item.dart';

class PantryBody extends ConsumerStatefulWidget {
  const PantryBody({super.key});

  @override
  ConsumerState<PantryBody> createState() => _PantryBodyState();
}

class _PantryBodyState extends ConsumerState<PantryBody> {
  final _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pantryNotifierProvider.notifier).loadInitial();
    });
  }

  Future<void> _quickAdd() async {
    final controller = TextEditingController();
    DateTime? pickedDate;

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un produit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('add_name_field'),
              controller: controller, 
              decoration: const InputDecoration(hintText: 'Nom')
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('add_qty_field'),
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantité (optionnel)'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.event),
                label: Text(pickedDate == null
                    ? 'Date de péremption (optionnel)'
                    : 'Péremption : ${pickedDate!.toLocal().toString().split(' ').first}'),
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 365 * 3)),
                    initialDate: pickedDate ?? now,
                  );
                  if (d != null) {
                    pickedDate = d;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('add_cancel_btn'),
            onPressed: () => Navigator.pop(context), 
            child: const Text('Annuler')
          ),
          FilledButton(
            key: const Key('add_save_btn'),
            onPressed: () => Navigator.pop(context, controller.text.trim()), 
            child: const Text('Ajouter')
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    final q = int.tryParse(_qtyCtrl.text);
    await ref.read(pantryNotifierProvider.notifier).addItem(
      PantryItem(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: name,
        quantity: q?.toDouble(),
        expirationDate: pickedDate,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" ajouté')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = ref.watch(pantryVisibleItemsProvider).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Bannière de conseils AI (auto-réactive)
          const PantryAdvisoryBanner(),

          // Barre de recherche / filtres
          PantryFiltersBar(
            searchText: ref.watch(pantrySearchTextProvider),
            onSearchChanged: ref.read(pantryNotifierProvider.notifier).setSearchTextDebounced,
            activeFilters: ref.watch(pantryActiveFiltersProvider).toList(),
            onClearFilters: ref.read(pantryActiveFiltersProvider).isNotEmpty
                ? ref.read(pantryNotifierProvider.notifier).clearFilters
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => ref.read(pantryNotifierProvider.notifier).scan(() {
                // appelle ton handler existant si tu veux garder la logique native
              }),
            ),
          ),

          const SizedBox(height: 8),

          // Liste ou état vide
          Expanded(
            child: hasItems
                ? const PantryListView()
                : PantryEmptyState(
                    title: 'Garde-manger vide',
                    message: "Ajoute un produit manuellement ou scanne un code-barres.",
                    cta: ElevatedButton.icon(
                      key: const Key('pantry_empty_add_btn'),
                      onPressed: _quickAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un produit'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

