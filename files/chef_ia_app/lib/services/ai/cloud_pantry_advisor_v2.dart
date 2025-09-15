// lib/services/ai/cloud_pantry_advisor_v2.dart
import 'package:chef_ia_app/services/ai/pantry_advisor_v2.dart';
import 'package:chef_ia_app/services/ai/cloud_client.dart';
import 'package:chef_ia_app/core/logging.dart';
import 'package:chef_ia_app/models/pantry_advisory.dart';

class CloudPantryAdvisorV2 implements PantryAdvisor {
  final PantryCloudClient client;
  final PantryAdvisor fallback;

  const CloudPantryAdvisorV2({required this.client, required this.fallback});

  @override
  List<PantryAdvisory> advise(PantryState state, PantryUserPrefs prefs) {
    final payload = _buildPayload(state, prefs);
    try {
      final t0 = DateTime.now();
      // NOTE: dans un vrai flux, fais cette méthode async.
      // Ici on garde la même signature sync → le client devra être mocké en test.
      throw UnimplementedError('Use async advise in real impl');
    } catch (e) {
      logEvent(module: 'advisor.cloud', event: 'cloud_failed_fallback', fields: {
        'error': e.toString(),
        'items': state.items.length,
        'topK': prefs.topK,
      }, level: 'WARN');
      return fallback.advise(state, prefs);
    }
  }

  Map<String, dynamic> _buildPayload(PantryState state, PantryUserPrefs prefs) {
    final items = state.items.map((i) => {
      'id': i.id,
      'category': i.category,
      'expiry': i.expiry?.toIso8601String(),
    }).toList();

    return {
      'schemaVersion': 1,
      'prefs': {'topK': prefs.topK, 'privacyCloud': prefs.privacyCloud},
      'items': items,
    };
  }
}
