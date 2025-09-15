import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour la persistance des préférences du garde-manger par foyer
final pantryPrefsProvider = Provider((ref) => PantryPrefsRepo());

class PantryPrefsRepo {
  static const _kSort = 'pantry.sort';
  static const _kFilter = 'pantry.filter';
  
  Future<void> saveSort(String householdId, String sort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kSort.$householdId', sort);
  }
  
  Future<String?> loadSort(String householdId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kSort.$householdId');
  }
  
  Future<void> saveFilter(String householdId, String filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kFilter.$householdId', filter);
  }
  
  Future<String?> loadFilter(String householdId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kFilter.$householdId');
  }
  
  Future<void> clearPrefs(String householdId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kSort.$householdId');
    await prefs.remove('$_kFilter.$householdId');
  }
}

