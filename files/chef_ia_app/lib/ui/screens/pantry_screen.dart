import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_app_bar.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_fab.dart';
import 'package:chef_ia_app/features/pantry/widgets/pantry_effects.dart';
import 'package:chef_ia_app/features/pantry/screens/pantry_body.dart';
import 'package:chef_ia_app/features/pantry/state/pantry_provider.dart';
import 'package:chef_ia_app/models/pantry_item.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});
  
  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  Future<void> _quickAdd() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un produit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nom du produit'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Ajouter')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final id = const Uuid().v4();
    await ref.read(pantryNotifierProvider.notifier).addItem(
      PantryItem(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: name,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" ajouté')));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SCREEN:/pantry',
      child: Scaffold(
        appBar: AppBar(title: const Text('Écran Garde-manger  •  /pantry')),
      body: Semantics(
        label: 'SCREEN:/pantry',
        child: const PantryEffects(child: PantryBody()),
      ),
      floatingActionButton: PantryFab(onAdd: _quickAdd      ),
    ),
    );
  }
}
