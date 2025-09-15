import 'package:flutter/material.dart';

class PantryEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final Widget? cta;

  const PantryEmptyState({
    super.key,
    this.title = 'Aucun produit',
    this.message = 'Ajoute tes premiers ingrédients pour commencer.',
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_outlined, size: 64),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (cta != null) ...[
              const SizedBox(height: 16),
              cta!,
            ]
          ],
        ),
      ),
    );
  }
}










