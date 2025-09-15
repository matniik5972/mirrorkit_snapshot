import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../state/pantry_provider.dart';
import '../advice/pantry_advisor_provider.dart';
import '../../../models/pantry_item.dart';

class PantryEffects extends ConsumerStatefulWidget {
  final Widget child;
  const PantryEffects({super.key, required this.child});
  @override
  ConsumerState<PantryEffects> createState() => _PantryEffectsState();
}

class _PantryEffectsState extends ConsumerState<PantryEffects> with WidgetsBindingObserver {
  late final ProviderSubscription<String?> _removeErrorSub;
  late final ProviderSubscription<List<PantryItem>> _removeItemsSub;
  Timer? _recalcDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // ✅ OK : listenManual autorisé hors build, penser à dispose()
    _removeErrorSub = ref.listenManual<String?>(
      pantryNotifierProvider.select((s) => s.error),
      (prev, err) {
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur garde-manger: $err')));
        }
      },
    );
    
    _removeItemsSub = ref.listenManual(
      pantryVisibleItemsProvider,
      (prev, next) {
        // ton effet ici (ex: debounced recompute IA)
        _scheduleRecompute();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ✅ Nettoyage des écoutes manuelles
    _removeErrorSub.close();
    _removeItemsSub.close();
    _recalcDebounce?.cancel();
    super.dispose();
  }

  void _scheduleRecompute() {
    _recalcDebounce?.cancel();
    _recalcDebounce = Timer(const Duration(milliseconds: 300), () async {
      ref.invalidate(pantryAdvisoryProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRecompute();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

