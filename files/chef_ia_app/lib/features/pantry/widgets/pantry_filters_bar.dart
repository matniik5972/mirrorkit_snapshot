import 'package:flutter/material.dart';

class PantryFiltersBar extends StatelessWidget {
  final String searchText;
  final ValueChanged<String> onSearchChanged;

  /// Ex: chips actifs, tags, etc.
  final List<String> activeFilters;
  final VoidCallback? onClearFilters;
  final Widget? trailing; // ex: bouton scan / tri

  const PantryFiltersBar({
    super.key,
    required this.searchText,
    required this.onSearchChanged,
    this.activeFilters = const [],
    this.onClearFilters,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: TextEditingController(text: searchText),
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Rechercher dans le garde-manger…',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: activeFilters
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(label: Text(f)),
                          ))
                      .toList(),
                ),
              ),
            ),
            if (onClearFilters != null && activeFilters.isNotEmpty)
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Réinitialiser'),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ],
    );
  }
}










