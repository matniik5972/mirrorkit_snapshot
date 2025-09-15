import 'package:flutter/material.dart';
import 'inbox_import.dart';

// EXEMPLE: adapte ce callback à ton modèle de garde‑manger
Future<void> upsertIntoPantry(ImportedPantryLine line) async {
  // 1) Mapper vers ton modèle (ex: PantryItem)
  // 2) Si l'item existe déjà → incrémente la quantité
  // 3) Sinon → crée l'entrée avec qty=line.qty
  // 4) Optionnel: stocker unitPrice si tu gères les prix
  
  // TODO: Implémente ta logique d'upsert ici
  // Exemple:
  // final existingItem = await findPantryItemByName(line.name);
  // if (existingItem != null) {
  //   await updatePantryItemQuantity(existingItem.id, existingItem.qty + line.qty);
  // } else {
  //   await createPantryItem(line);
  // }
}

class HomeBoot extends StatefulWidget {
  const HomeBoot({super.key});
  @override
  State<HomeBoot> createState() => _HomeBootState();
}

class _HomeBootState extends State<HomeBoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final imported = await importFromCoursesInbox(onUpsert: upsertIntoPantry);
      if (imported > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Garde‑manger mis à jour : +$imported article(s)')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // ou ton vrai Home
  }
}

/// Exemple d'utilisation dans un écran de paramètres / garde‑manger
class PantryImportButton extends StatelessWidget {
  const PantryImportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        final imported = await importFromCoursesInbox(onUpsert: upsertIntoPantry);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(imported > 0
                ? 'Importé : +$imported article(s)'
                : 'Rien à importer'),
            ),
          );
        }
      },
      icon: const Icon(Icons.move_to_inbox),
      label: const Text('Importer depuis Courses'),
    );
  }
}






