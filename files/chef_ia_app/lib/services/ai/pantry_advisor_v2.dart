import '../../models/pantry_item.dart';
import '../../models/pantry_advisory.dart';

class PantryState {
  final List<PantryItem> items;
  const PantryState({required this.items});
}

class PantryUserPrefs {
  final bool useCloud;
  final bool privacyCloud;
  final int topK;
  const PantryUserPrefs({
    this.useCloud = true,
    this.privacyCloud = true,
    this.topK = 10,
  });
}

abstract class PantryAdvisor {
  List<PantryAdvisory> advise(PantryState state, PantryUserPrefs prefs);
}











