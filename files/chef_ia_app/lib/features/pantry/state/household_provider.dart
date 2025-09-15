import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/household.dart';

final currentHouseholdIdProvider = StateProvider<String?>((_) => null); // null = mode solo (local)
final householdsProvider = StateNotifierProvider<_Households, List<Household>>((_) => _Households());

class _Households extends StateNotifier<List<Household>> {
  _Households() : super(const []);
  
  void createLocal(String name, String id) {
    final hh = Household(id: id, name: name);
    state = [...state, hh];
  }
  
  void rename(String id, String name) {
    state = state.map((h) => h.id == id ? h.copyWith(name: name, updatedAt: DateTime.now()) : h).toList();
  }
}
