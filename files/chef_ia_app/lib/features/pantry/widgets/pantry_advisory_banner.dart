import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chef_ia_app/features/pantry/advice/pantry_advisor_provider.dart';
import 'package:chef_ia_app/features/pantry/state/pantry_provider.dart';

class PantryAdvisoryBanner extends ConsumerWidget {
  const PantryAdvisoryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advisories = ref.watch(pantryAdvisoryProvider);

    return advisories.when(
      data: (advisories) {
        if (advisories.isEmpty) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              for (final a in advisories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(a.label),
                    onPressed: () {
                      switch (a.type) {
                        case 'FILTER':
                          ref.read(pantryNotifierProvider.notifier).applySmartFilter(a.label);
                          break;
                        case 'HANDOFF_CHEF':
                          ref.read(pantryNotifierProvider.notifier).handoffToChef(a);
                          break;
                        case 'HANDOFF_COURSES':
                          ref.read(pantryNotifierProvider.notifier).handoffToCourses(a);
                          break;
                        case 'NAVIGATE':
                          ref.read(pantryNotifierProvider.notifier).navigateForAdvisory(a);
                          break;
                        // (compatibilité si l'ancien type existe encore quelque part)
                        case 'RECIPE':
                          ref.read(pantryNotifierProvider.notifier).handoffToChef(a);
                          break;
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 4),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

