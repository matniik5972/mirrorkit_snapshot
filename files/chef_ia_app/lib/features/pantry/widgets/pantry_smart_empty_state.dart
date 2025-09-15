import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Empty-state intelligent et actionnable pour le garde-manger
class PantrySmartEmptyState extends StatelessWidget {
  final VoidCallback? onScan;
  final VoidCallback? onManual;
  final VoidCallback? onImport;
  final String? title;
  final String? message;

  const PantrySmartEmptyState({
    super.key,
    this.onScan,
    this.onManual,
    this.onImport,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône principale
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Titre
          Text(
            title ?? 'Votre garde-manger est vide',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Message
          Text(
            message ?? 'Commencez par ajouter des produits en les scannant ou en saisissant les informations manuellement.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Actions
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              if (onScan != null)
                FilledButton.icon(
                  onPressed: () {
                    Feedback.forTap(context);
                    onScan!();
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scanner'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              
              if (onManual != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Feedback.forTap(context);
                    onManual!();
                  },
                  icon: const Icon(Icons.keyboard),
                  label: const Text('Saisie manuelle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              
              if (onImport != null)
                TextButton.icon(
                  onPressed: () {
                    Feedback.forTap(context);
                    onImport!();
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importer'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Conseil IA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Conseil : Scannez les codes-barres pour une reconnaissance automatique des produits.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty-state spécialisé pour les résultats de recherche vides
class PantrySearchEmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClearSearch;

  const PantrySearchEmptyState({
    super.key,
    required this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Aucun résultat pour "$searchQuery"',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Essayez avec d\'autres mots-clés ou vérifiez l\'orthographe.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          if (onClearSearch != null)
            FilledButton.icon(
              onPressed: () {
                Feedback.forTap(context);
                onClearSearch!();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Effacer la recherche'),
            ),
        ],
      ),
    );
  }
}

