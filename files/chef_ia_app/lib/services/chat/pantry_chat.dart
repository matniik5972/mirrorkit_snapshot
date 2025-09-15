import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/pantry_item.dart';
import '../ai/local_pantry_advisor_v2.dart'; // pour petite logique si cloud KO
import 'package:http/http.dart' as http;

class PantryUserPrefs {
  final bool glutenFree, lactoseFree;
  final double? budgetPerMeal;
  final bool useCloud;
  final bool privacyCloud;
  final int topK;
  const PantryUserPrefs({
    this.glutenFree=false, 
    this.lactoseFree=false, 
    this.budgetPerMeal,
    this.useCloud = true,
    this.privacyCloud = true,
    this.topK = 10,
  });
}

class PantryChatContext {
  final List<PantryItem> items;
  final List<String> nearExpiryIds;
  final DateTime now;
  final bool locationAllowed;
  final String? locationApprox; // ex: "Paris, FR"
  final double? temperatureC;
  final PantryUserPrefs userPrefs;

  PantryChatContext({
    required this.items,
    required this.nearExpiryIds,
    required this.now,
    required this.locationAllowed,
    required this.locationApprox,
    required this.temperatureC,
    required this.userPrefs,
  });

  factory PantryChatContext.fromNow({
    required List<PantryItem> items,
    required List<String> nearExpiryIds,
    required bool locationAllowed,
    String? locationApprox,
    double? temperatureC,
    PantryUserPrefs userPrefs = const PantryUserPrefs(),
  }) => PantryChatContext(
        items: items,
        nearExpiryIds: nearExpiryIds,
        now: DateTime.now(),
        locationAllowed: locationAllowed,
        locationApprox: locationApprox,
        temperatureC: temperatureC,
        userPrefs: userPrefs,
      );

  Map<String, dynamic> toJson() => {
    'now': now.toIso8601String(),
    'nearExpiryIds': nearExpiryIds,
    'locationAllowed': locationAllowed,
    'locationApprox': locationApprox,
    'temperatureC': temperatureC,
    'userPrefs': {
      'glutenFree': userPrefs.glutenFree,
      'lactoseFree': userPrefs.lactoseFree,
      'budgetPerMeal': userPrefs.budgetPerMeal,
    },
    'pantry': items.map((e) => {
      'id': e.id,
      'name': e.name,
      'qty': e.quantity,
      'unit': e.unit,
      'category': e.category,
      'expiryISO': e.expiry?.toIso8601String(),
      'barcode': e.barcode,
    }).toList(),
  };
}

class PantryChat {
  // Sélection naïve top-K par similarité texte (peut être remplacée par embeddings)
  List<PantryItem> pickTopK(List<PantryItem> items, String query, {int k = 20}) {
    final q = query.toLowerCase();
    final scored = items.map((e) {
      final hay = '${e.name} ${e.category} ${e.barcode ?? ''}'.toLowerCase();
      final score = hay.contains(q) ? 2 : 0 + (e.name.toLowerCase().startsWith(q) ? 1 : 0);
      return (e: e, s: score);
    }).toList()
      ..sort((a, b) => b.s.compareTo(a.s));
    return scored.take(k).map((x) => x.e).toList();
  }

  Future<Map<String, dynamic>> askCloud(String query, PantryChatContext ctx, {Duration? timeout}) async {
    try {
      final resp = await http.post(
        Uri.parse('https://your-backend.example.com/pantry/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'context': ctx.toJson(),
        }),
      ).timeout(timeout ?? const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {/* ignore */}
    // Fallback local minimal
    final local = LocalPantryAdvisor();
    final soon = ctx.items.where((x) {
      final st = local.evaluate(x);
      return st.status == ExpiryStatus.soon || st.status == ExpiryStatus.grace;
    }).toList();
    return {
      'answer': soon.isNotEmpty
          ? "Pense à utiliser : ${soon.map((e)=>e.name).take(3).join(', ')} (bientôt périmés)."
          : "Je n'ai rien vu d'urgent. Que veux-tu cuisiner ?",
      'suggestions': [
        "Idées avec ${soon.isNotEmpty ? soon.first.name : 'tes produits courants'}",
        "Recettes < 30 min",
        "Sans gaspillage",
      ],
      'actions': [],
      'debug': {'fallback':'local'}
    };
  }

  Map<String, dynamic> askCloudFallback(String query, PantryChatContext ctx) {
    final local = LocalPantryAdvisor();
    final soon = ctx.items.where((x) {
      final st = local.evaluate(x);
      return st.status == ExpiryStatus.soon || st.status == ExpiryStatus.grace;
    }).toList();
    return {
      'answer': soon.isNotEmpty
          ? "Pense à utiliser : ${soon.map((e)=>e.name).take(3).join(', ')} (bientôt périmés)."
          : "Je n'ai rien vu d'urgent. Que veux-tu cuisiner ?",
      'suggestions': [
        "Idées avec ${soon.isNotEmpty ? soon.first.name : 'tes produits courants'}",
        "Recettes < 30 min",
        "Sans gaspillage",
      ],
      'actions': [],
      'debug': {'fallback':'local'}
    };
  }

  String? localHint(List<PantryItem> top, List<String> near) {
    if (near.isEmpty) return null;
    final nearItems = top.where((e) => near.contains(e.id)).take(3).toList();
    if (nearItems.isEmpty) return null;
    return "💡 Pense à utiliser : ${nearItems.map((e) => e.name).join(', ')} (bientôt périmés)";
  }

  String render(Map<String, dynamic> json) {
    final ans = json['answer'] ?? '';
    final sugg = (json['suggestions'] as List?)?.cast<String>() ?? const [];
    if (sugg.isEmpty) return ans;
    return "$ans\n\n• ${sugg.join('\n• ')}";
  }

  void runActions(Map<String, dynamic> json, BuildContext ctx) {
    final acts = (json['actions'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    for (final a in acts) {
      switch (a['type']) {
        case 'open_recipe_prompt':
          final ids = (a['items'] as List).cast<String>();
          Navigator.pushNamed(ctx, '/chat', arguments: {
            'prompt': "Propose 3 recettes avec : ${ids.join(', ')}"
          });
          break;
        case 'mark_shopping':
          // TODO: ajouter à la liste de courses
          break;
      }
    }
  }
}
