import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chef_ia_app/features/pantry/state/pantry_provider.dart';
import 'package:chef_ia_app/features/pantry/pantry_sender.dart';
import 'package:chef_ia_app/models/pantry_item.dart';

class PantryItemTile extends ConsumerWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final PantryItem? item;

  const PantryItemTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: item != null ? _buildSubtitle(item!) : (subtitle != null ? Text(subtitle!) : null),
      trailing: trailing ?? (item != null ? _buildQuickActions(context, ref, item!) : null),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildSubtitle(PantryItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.quantity != null) Text('Qté : ${item.quantity!.toInt()}'),
        if (item.expirationDate != null)
          Text('Péremption : ${item.expirationDate!.toLocal().toString().split(' ').first}'),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, PantryItem item) {
    return PopupMenuButton<int>(
      onSelected: (v) async {
        if (v == 1) {
          // Consommer −1
          final q = (item.quantity ?? 1.0);
          final newQ = (q > 0) ? q - 1.0 : 0.0;
          await ref.read(pantryNotifierProvider.notifier)
            .updateItem(item.copyWith(quantity: newQ));
        } else if (v == 2) {
          // Supprimer avec Undo
          final removed = item;
          await ref.read(pantryNotifierProvider.notifier).removeItem(item.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} supprimé'),
                action: SnackBarAction(
                  label: 'Annuler',
                  onPressed: () async {
                    // Tentative de restauration avec fallback
                    final store = ref.read(pantryStoreProvider);
                    if (store != null) {
                      final restored = await store.restoreItem(removed.id);
                      if (!restored) {
                        // Si purge entre temps, on re-upsert la copie locale
                        await store.upsert(removed);
                      }
                    } else {
                      // Fallback direct
                      await ref.read(pantryNotifierProvider.notifier).addItem(removed);
                    }
                  },
                ),
              ),
            );
          }
        } else if (v == 3) {
          // Envoyer vers Courses
          try {
            final payload = toPayload(item);
            await sendPantryToCourses({'items': [payload]});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} ajouté à la liste de courses')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 1, child: Text('Consommer (−1)')),
        PopupMenuItem(value: 2, child: Text('Supprimer')),
        PopupMenuItem(value: 3, child: Text('Ajouter à la liste de courses')),
      ],
    );
  }
}
