import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart';
import '../../models/pantry_item.dart';

/// Envoie le panier de ChefIA Cuisine vers ChefIA Courses via Broadcast Intent
/// ✅ Marche sans Internet
/// ✅ L'utilisateur n'a pas besoin d'ouvrir Courses
/// ✅ Le Receiver + WorkManager se chargent du reste
Future<void> sendPantryToCourses(Map<String, dynamic> payload) async {
  final jsonStr = jsonEncode(payload);
  final intent = AndroidIntent(
    action: 'com.chefia.courses.IMPORT_PANTRY',
    package: 'com.chefia.courses', // ← remplace par le package exact de Courses
    arguments: <String, dynamic>{
      'payload': jsonStr, // ou 'payload_b64': base64Url.encode(utf8.encode(jsonStr))
    },
  );
  await intent.sendBroadcast();
}

/// Helper pour créer le payload du panier
Map<String, dynamic> createPantryPayload({
  required List<Map<String, dynamic>> items,
  String? recipeName,
  String? origin,
}) {
  return {
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'recipeName': recipeName,
    'origin': origin ?? 'recipe',
    'items': items,
  };
}

/// Exemple d'utilisation pour envoyer un panier de recette
Future<void> sendRecipePantryToCourses({
  required String recipeName,
  required List<Map<String, dynamic>> ingredients,
}) async {
  final payload = createPantryPayload(
    items: ingredients,
    recipeName: recipeName,
    origin: 'recipe',
  );
  
  await sendPantryToCourses(payload);
}

/// Helper pour convertir un PantryItem en payload
Map<String, dynamic> toPayload(PantryItem it) => {
  'id': it.id,
  'name': it.name,
  'quantity': it.quantity,
  'unit': it.unit,
  'category': it.category,
  'expiry': it.expiry?.toIso8601String(),
  'barcode': it.barcode,
  'updatedAt': it.updatedAt.toIso8601String(),
  'source': it.source ?? 'chefia',
  'householdId': it.householdId,
};






