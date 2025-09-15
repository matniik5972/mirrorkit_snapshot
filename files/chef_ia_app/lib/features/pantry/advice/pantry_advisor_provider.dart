import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:chef_ia_app/features/pantry/state/pantry_provider.dart';
import 'package:chef_ia_app/services/ai/pantry_advisor_v2.dart';
import 'package:chef_ia_app/services/ai/local_pantry_advisor_v2.dart';
import 'package:chef_ia_app/models/pantry_advisory.dart';

const bool kCloudAdviceEnabled = bool.fromEnvironment('CHEFIA_ADVICE_CLOUD', defaultValue: false);
const String? kCloudAdviceEndpoint = String.fromEnvironment('CHEFIA_ADVICE_ENDPOINT');

final pantryAdvisorProvider = Provider<PantryAdvisor>((ref) {
  final local = LocalPantryAdvisor();
  final cloud = (kCloudAdviceEnabled && kCloudAdviceEndpoint != null)
      ? CloudPantryAdvisor(endpoint: kCloudAdviceEndpoint!)
      : const NoopCloudPantryAdvisor();
  return HybridPantryAdvisor(local: local, cloud: cloud);
});

/// Produit des conseils asynchrones basés sur les items visibles
final pantryAdvisoryProvider = FutureProvider.autoDispose<List<SimplePantryAdvisory>>((ref) async {
  final advisor = ref.watch(pantryAdvisorProvider);
  final items = ref.watch(pantryVisibleItemsProvider);
  if (items.isEmpty) return [];
  return advisor.compute(items);
});

