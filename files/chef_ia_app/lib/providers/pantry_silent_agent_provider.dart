// lib/providers/pantry_silent_agent_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chef_ia_app/agents/pantry_silent_agent.dart';
import 'package:chef_ia_app/core/grace_policy.dart';
import 'package:chef_ia_app/services/ai/pantry_advisor_v2.dart';
import 'package:chef_ia_app/services/ai/local_pantry_advisor_v2.dart';
import 'package:chef_ia_app/services/ai/cloud_pantry_advisor_v2.dart';
import 'package:chef_ia_app/services/ai/cloud_client.dart';
import 'package:chef_ia_app/core/clock.dart';

/// Client cloud factice pour démarrer (à remplacer par ton vrai client)
class DummyCloudClient implements PantryCloudClient {
  @override
  Future<List<Map<String, dynamic>>> advise(Map<String, dynamic> payload, {Duration timeout = const Duration(seconds: 2)}) async {
    // Simule un échec pour exercer le fallback local en dev
    throw Exception('dummy cloud not implemented');
  }
}

final pantrySilentAgentProvider = Provider<PantrySilentAgent>((ref) {
  final grace = const GracePolicy();
  final local = LocalPantryAdvisor(clock: const SystemClock(), policy: grace, topK: 10);
  final cloud = CloudPantryAdvisorV2(client: DummyCloudClient(), fallback: local);
  final agent = PantrySilentAgent(local: local, cloud: cloud, grace: grace);
  agent.start();
  ref.onDispose(agent.stop);
  return agent;
});











