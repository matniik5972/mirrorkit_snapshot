import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/pantry_provider.dart';

class PantryFab extends ConsumerWidget {
  final VoidCallback? onAdd;
  const PantryFab({super.key, this.onAdd});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      key: const Key('pantry_add_item_fab'),
      onPressed: () => _showAddBottomSheet(context, ref),
      child: const Icon(Icons.add),
    );
  }

  void _showAddBottomSheet(BuildContext context, WidgetRef ref) {
    Feedback.forTap(context); // Haptique léger
    
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => SafeArea(
        minimum: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              visualDensity: VisualDensity.standard,
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: const Text('Scanner un code-barres'),
              subtitle: const Text('Utilisez l\'appareil photo pour scanner'),
              onTap: () {
                Feedback.forTap(context);
                Navigator.pop(context);
                // TODO: Implémenter le scan de code-barres
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scan de code-barres - À implémenter')),
                );
              },
            ),
            ListTile(
              visualDensity: VisualDensity.standard,
              leading: const Icon(Icons.photo_camera_back_rounded),
              title: const Text('Photo / Reconnaissance'),
              subtitle: const Text('Reconnaissance automatique du produit'),
              onTap: () {
                Feedback.forTap(context);
                Navigator.pop(context);
                // TODO: Implémenter la reconnaissance d'image
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reconnaissance d\'image - À implémenter')),
                );
              },
            ),
            ListTile(
              visualDensity: VisualDensity.standard,
              leading: const Icon(Icons.keyboard_rounded),
              title: const Text('Saisie manuelle'),
              subtitle: const Text('Ajouter un produit manuellement'),
              onTap: () {
                Feedback.forTap(context);
                Navigator.pop(context);
                onAdd?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

