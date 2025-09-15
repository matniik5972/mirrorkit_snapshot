// lib/providers/pantry_prefs_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PantryPrefs {
  final bool useCloud;
  final bool privacyCloud;
  final int topK;
  final Map<String, int> graceByCategory;

  const PantryPrefs({
    required this.useCloud,
    required this.privacyCloud,
    required this.topK,
    required this.graceByCategory,
  });

  PantryPrefs copyWith({
    bool? useCloud,
    bool? privacyCloud,
    int? topK,
    Map<String, int>? graceByCategory,
  }) {
    return PantryPrefs(
      useCloud: useCloud ?? this.useCloud,
      privacyCloud: privacyCloud ?? this.privacyCloud,
      topK: topK ?? this.topK,
      graceByCategory: graceByCategory ?? this.graceByCategory,
    );
  }

  Map<String, Object?> toMap() => {
        'useCloud': useCloud,
        'privacyCloud': privacyCloud,
        'topK': topK,
        'graceByCategory': graceByCategory,
      };

  static PantryPrefs fromMap(Map<String, Object?> m) => PantryPrefs(
        useCloud: m['useCloud'] as bool? ?? true,
        privacyCloud: m['privacyCloud'] as bool? ?? true,
        topK: m['topK'] as int? ?? 10,
        graceByCategory: (m['graceByCategory'] as Map?)?.cast<String, int>() ??
            const {
              'frais': 2,
              'charcuterie': 0,
              'viande': 0,
              'poisson': 0,
              'épicerie': 7,
              'boissons': 7,
              'surgelé': 30,
            },
      );
}

final pantryPrefsProvider =
    NotifierProvider<PantryPrefsNotifier, PantryPrefs>(PantryPrefsNotifier.new);

class PantryPrefsNotifier extends Notifier<PantryPrefs> {
  static const _kUseCloud = 'pantry.useCloud';
  static const _kPrivacy = 'pantry.privacyCloud';
  static const _kTopK = 'pantry.topK';
  static const _kGrace = 'pantry.graceByCategory';

  late SharedPreferences _sp;

  @override
  PantryPrefs build() {
    // Valeurs par défaut synchrones (seront écrasées après load async)
    final defaults = PantryPrefs.fromMap(const {});
    _load();
    return defaults;
  }

  Future<void> _load() async {
    _sp = await SharedPreferences.getInstance();
    final useCloud = _sp.getBool(_kUseCloud) ?? true;
    final privacy = _sp.getBool(_kPrivacy) ?? true;
    final topK = _sp.getInt(_kTopK) ?? 10;

    final graceRaw = _sp.getStringList(_kGrace);
    Map<String, int> graceByCat;
    if (graceRaw == null) {
      graceByCat = PantryPrefs.fromMap(const {}).graceByCategory;
    } else {
      graceByCat = {
        for (final e in graceRaw)
          e.split('=').first: int.tryParse(e.split('=').last) ?? 0
      };
    }
    state = PantryPrefs(
      useCloud: useCloud,
      privacyCloud: privacy,
      topK: topK,
      graceByCategory: graceByCat,
    );
  }

  Future<void> updateFromMap(Map<String, dynamic> m) async {
    final next = state.copyWith(
      useCloud: m['useCloud'] as bool?,
      privacyCloud: m['privacyCloud'] as bool?,
      topK: m['topK'] as int?,
      graceByCategory: (m['graceByCategory'] as Map?)?.cast<String, int>(),
    );
    state = next;
    await _persist(next);
  }

  Future<void> _persist(PantryPrefs p) async {
    await _sp.setBool(_kUseCloud, p.useCloud);
    await _sp.setBool(_kPrivacy, p.privacyCloud);
    await _sp.setInt(_kTopK, p.topK);
    await _sp.setStringList(
      _kGrace,
      p.graceByCategory.entries.map((e) => '${e.key}=${e.value}').toList(),
    );
  }
}











