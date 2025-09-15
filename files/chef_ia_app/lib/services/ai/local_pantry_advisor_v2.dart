import 'package:chef_ia_app/core/clock.dart';
import 'package:chef_ia_app/core/grace_policy.dart';
import 'package:chef_ia_app/core/logging.dart';
import 'package:chef_ia_app/models/pantry_item.dart';
import 'package:chef_ia_app/models/pantry_advisory.dart';
import 'pantry_advisor_v2.dart';

class LocalPantryAdvisor implements PantryAdvisor {
  final Clock clock;
  final GracePolicy policy;
  final int topK;
  
  const LocalPantryAdvisor({
    this.clock = const SystemClock(),
    this.policy = const GracePolicy(),
    this.topK = 10,
  });

  @override
  List<PantryAdvisory> advise(PantryState state, PantryUserPrefs prefs) {
    final t0 = DateTime.now();
    final items = state.items;
    
    // Classement par urgence: expired > grace > soon > fresh
    int score(PantryItem item) {
      final s = item.statusWith(clock, policy);
      return switch (s) {
        ExpiryStatus.expired => 100,
        ExpiryStatus.grace => 80,
        ExpiryStatus.soon => 50,
        _ => 0,
      };
    }
    
    final sorted = [...items]..sort((a, b) => score(b).compareTo(score(a)));
    final focus = sorted.take(topK).toList();
    
    final advisories = <PantryAdvisory>[];
    
    // Grouper par statut
    final expired = focus.where((i) => i.statusWith(clock, policy) == ExpiryStatus.expired).toList();
    final grace = focus.where((i) => i.statusWith(clock, policy) == ExpiryStatus.grace).toList();
    final soon = focus.where((i) => i.statusWith(clock, policy) == ExpiryStatus.soon).toList();
    
    if (expired.isNotEmpty) {
      advisories.add(PantryAdvisory(
        id: 'expired_${DateTime.now().millisecondsSinceEpoch}',
        type: AdvisoryType.expireSoon,
        title: 'Produits expirés',
        body: '${expired.length} produit(s) expiré(s) à jeter',
        reason: 'Ces produits ont dépassé leur date de péremption',
        itemIds: expired.map((e) => e.id).toList(),
        priority: 1,
        createdAt: clock.now(),
        actions: [
          PantryAdvisoryAction('FILTER', {'status': 'expired'}),
          PantryAdvisoryAction('RECIPE', {'items': expired.map((e) => e.id).toList()}),
        ],
      ));
    }
    
    if (grace.isNotEmpty) {
      advisories.add(PantryAdvisory(
        id: 'grace_${DateTime.now().millisecondsSinceEpoch}',
        type: AdvisoryType.grace,
        title: 'Période de grâce',
        body: '${grace.length} produit(s) en période de grâce',
        reason: 'Ces produits sont expirés mais encore consommables',
        itemIds: grace.map((e) => e.id).toList(),
        priority: 2,
        createdAt: clock.now(),
        actions: [
          PantryAdvisoryAction('FILTER', {'status': 'grace'}),
          PantryAdvisoryAction('RECIPE', {'items': grace.map((e) => e.id).toList()}),
        ],
      ));
    }
    
    if (soon.isNotEmpty) {
      advisories.add(PantryAdvisory(
        id: 'soon_${DateTime.now().millisecondsSinceEpoch}',
        type: AdvisoryType.expireSoon,
        title: 'Bientôt périmés',
        body: '${soon.length} produit(s) à consommer rapidement',
        reason: 'Ces produits expirent dans les 3 prochains jours',
        itemIds: soon.map((e) => e.id).toList(),
        priority: 3,
        createdAt: clock.now(),
        actions: [
          PantryAdvisoryAction('FILTER', {'status': 'soon'}),
          PantryAdvisoryAction('RECIPE', {'items': soon.map((e) => e.id).toList()}),
        ],
      ));
    }
    
    final dt = DateTime.now().difference(t0).inMilliseconds;
    logEvent(module: 'advisor.local', event: 'advise_done', fields: {
      'topK': prefs.topK,
      'items': state.items.length,
      'advisories': advisories.length,
      'ms': dt,
    });
    
    return advisories;
  }
}
