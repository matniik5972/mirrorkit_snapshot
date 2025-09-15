import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/storage/pantry_store.dart';

/// Mixin pour ajouter les fonctionnalités d'export/import au PantryScreen
mixin PantryExportImportMixin {
  PantryStore get pantryStore;
  Future<void> Function() get reloadPantry;
  void Function(String) get showToast;

  /// Exporte le garde-manger en JSON
  Future<void> exportPantry() async {
    try {
      final json = await pantryStore.exportAsJson();
      
      // Copier dans le presse-papiers
      await Clipboard.setData(ClipboardData(text: json));
      
      showToast("Garde-manger exporté dans le presse-papiers !");
      
      // Optionnel : sauvegarder dans un fichier
      // TODO: implémenter la sauvegarde de fichier si nécessaire
    } catch (e) {
      showToast("Erreur lors de l'export: $e");
    }
  }

  /// Importe un garde-manger depuis le presse-papiers
  Future<void> importPantry(BuildContext context) async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        showToast("Aucune donnée dans le presse-papiers");
        return;
      }

      // Demander confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Importer un garde-manger'),
          content: const Text(
            'Cela va ajouter les articles du presse-papiers à votre garde-manger actuel. '
            'Les doublons seront mis à jour automatiquement.\n\n'
            'Continuer ?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Importer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Importer
      final result = await pantryStore.importFromJson(clipboardData.text!);
      
      showToast(
        "Import terminé: ${result['added']} ajoutés, "
        "${result['updated']} mis à jour, "
        "${result['skipped']} ignorés"
      );

      // Recharger la liste
      await reloadPantry();
    } catch (e) {
      showToast("Erreur lors de l'import: $e");
    }
  }
}










