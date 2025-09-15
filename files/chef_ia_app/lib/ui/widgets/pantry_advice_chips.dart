import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chef_ia_app/core/event_bus.dart';
import 'package:chef_ia_app/models/pantry_advisory.dart';

class PantryAdviceChips extends StatefulWidget {
  const PantryAdviceChips({super.key});
  @override
  State<PantryAdviceChips> createState() => _PantryAdviceChipsState();
}

class _PantryAdviceChipsState extends State<PantryAdviceChips> {
  StreamSubscription? _sub;
  List<PantryAdvisory> _advisories = const [];

  @override
  void initState() {
    super.initState();
    // Écoute les conseils silencieux
    _sub = EventBus()
        .on('pantry.advisory.ready')
        .listen((e) => _onAdvisoriesEvent(e as Map<String, dynamic>));
    // Option : demande immédiate au démarrage de l'écran
    EventBus().emit('pantry.chat.requested', {'reason': 'screen_open'});
  }

  void _onAdvisoriesEvent(Map<String, dynamic> e) {
    final pay = (e['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final list = (pay['advisories'] as List?) ?? const [];
    final parsed = list
        .whereType<Map>()
        .map((m) => PantryAdvisory.fromJson(m.cast<String, dynamic>()))
        .toList();
    // Décale le setState après frame pour éviter les conflits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _advisories = parsed);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_advisories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip(label: Text('Rien d\'urgent')),
            Chip(label: Text('Idées < 30 min')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _advisories.take(6).map((a) {
          final label = a.title.isNotEmpty ? a.title : (a.reason ?? 'Conseil');
          return ActionChip(
            label: Text(label, overflow: TextOverflow.ellipsis),
            onPressed: () => _runFirstAction(context, a),
          );
        }).toList(),
      ),
    );
  }

  void _runFirstAction(BuildContext context, PantryAdvisory a) {
    if (a.actions.isEmpty) return;

    // On gère quelques actions standards : FILTER / RECIPE / NAVIGATE
    final act = a.actions.first;
    switch (act.action) {
      case 'FILTER':
        // act.params ex: {'status':'soon'} ou {'category':'frais'}
        EventBus().emit('pantry.ui.apply_filter', act.params);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filtre appliqué : ${act.params}')),
        );
        break;
      case 'RECIPE':
        // act.params ex: {'with':['lait','oeufs']}
        EventBus().emit('recipes.requested', act.params);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ouverture des idées de recettes…')),
        );
        break;
      case 'NAVIGATE':
        // act.params ex: {'route':'/pantry', 'args': {'tab':'soon'}}
        final route = act.params['route'] as String? ?? '/pantry';
        final args  = act.params['args'];
        Navigator.of(context).pushNamed(route, arguments: args);
        break;
      default:
        // fallback : rien
        break;
    }
  }
}

