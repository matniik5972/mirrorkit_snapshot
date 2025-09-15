import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../state/pantry_provider.dart';
import '../state/household_provider.dart';

class PantryAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PantryAppBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(pantryTotalCountProvider);
    final currentHH = ref.watch(currentHouseholdIdProvider);
    return AppBar(
      title: Text('Garde-manger ($total)'),
      actions: [
        PopupMenuButton<String>(
          key: const Key('pantry_menu_btn'),
          onSelected: (v) async {
            if (v == 'switch') {
              final id = await _pickHouseholdDialog(context, ref);
              if (id != null) {
                ref.read(currentHouseholdIdProvider.notifier).state = id;
                await ref.read(pantryNotifierProvider.notifier).loadInitial();
              }
            } else if (v == 'about') {
              // TODO: Afficher dialog à propos
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'switch', child: Text('Changer de foyer')),
            const PopupMenuItem(value: 'about', child: Text('À propos')),
          ],
        ),
        IconButton(
          key: const Key('pantry_refresh_btn'),
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(pantryNotifierProvider.notifier).loadInitial(),
        ),
      ],
    );
  }

  Future<String?> _pickHouseholdDialog(BuildContext context, WidgetRef ref) async {
    final households = ref.read(householdsProvider);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choisir un foyer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...households.map((h) => ListTile(
              title: Text(h.name),
              onTap: () => Navigator.pop(context, h.id),
            )),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Créer un nouveau foyer'),
              onTap: () async {
                Navigator.pop(context);
                final name = await _createHouseholdDialog(context);
                if (name != null) {
                  final id = 'hh_${const Uuid().v4()}';
                  ref.read(householdsProvider.notifier).createLocal(name, id);
                  Navigator.pop(context, id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _createHouseholdDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Créer un foyer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nom du foyer'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

