// lib/ui/screens/pantry_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chef_ia_app/providers/pantry_prefs_provider.dart';
import 'package:chef_ia_app/providers/grace_policy_provider.dart';
import 'package:chef_ia_app/core/grace_policy.dart';

class PantrySettingsScreen extends ConsumerStatefulWidget {
  const PantrySettingsScreen({super.key});
  @override
  ConsumerState<PantrySettingsScreen> createState() => _PantrySettingsScreenState();
}

class _PantrySettingsScreenState extends ConsumerState<PantrySettingsScreen> {
  final _controllerTopK = TextEditingController(text: '10');
  Map<String, int>? _grace; // nullable → pas de LateInitializationError
  bool _useCloud = true;
  bool _privacyCloud = true;

  @override
  void dispose() {
    _controllerTopK.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(pantryPrefsProvider);
    // init paresseuse une seule fois
    _grace ??= Map<String, int>.from(prefs.graceByCategory);
    _useCloud = prefs.useCloud;
    _privacyCloud = prefs.privacyCloud;
    // évite de réécrire le texte à chaque build (saut du curseur) :
    if (_controllerTopK.text != prefs.topK.toString()) {
      _controllerTopK.text = prefs.topK.toString();
    }
    final graceMap = _grace!;             // désormais non-null ici
    final cats = graceMap.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages Garde-manger')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Utiliser l\'IA Cloud'),
            value: _useCloud,
            onChanged: (v) => setState(() => _useCloud = v),
          ),
          SwitchListTile(
            title: const Text('Anonymiser avant envoi Cloud'),
            value: _privacyCloud,
            onChanged: (v) => setState(() => _privacyCloud = v),
          ),
          TextField(
            controller: _controllerTopK,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Top-K (produits concernés)'),
          ),
          const SizedBox(height: 12),
          const Text('Périodes de grâce (jours) par catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final c in cats)
            Row(
              children: [
                Expanded(child: Text(c)),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: graceMap[c].toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {
                      graceMap[c] = int.tryParse(v) ?? graceMap[c]!;
                    }),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final topK = int.tryParse(_controllerTopK.text) ?? 10;
              final mapToSave = Map<String,int>.from(_grace!);
              ref.read(pantryPrefsProvider.notifier).updateFromMap({
                'useCloud': _useCloud,
                'privacyCloud': _privacyCloud,
                'topK': topK,
                'graceByCategory': mapToSave,
              });
              // sync GracePolicy globale (utilisée par LocalPantryAdvisorV2)
              ref.read(gracePolicyProvider.notifier).setGraceByCategory(mapToSave);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
