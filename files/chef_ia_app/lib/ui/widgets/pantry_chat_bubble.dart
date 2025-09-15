import 'package:flutter/material.dart';
import '../../services/ai/pantry_advisor_v2.dart';
import '../../services/chat/pantry_chat.dart';
import '../../models/pantry_item.dart' as new_model;

class PantryChatBubble extends StatefulWidget {
  final List<new_model.PantryItem> items;
  final PantryAdvisor advisor;
  final void Function(List<String> itemIds) onOpenRecipe;
  final String? initialQuery;

  const PantryChatBubble({
    super.key,
    required this.items,
    required this.advisor,
    required this.onOpenRecipe,
    this.initialQuery,
  });

  @override
  State<PantryChatBubble> createState() => _PantryChatBubbleState();
}

class _PantryChatBubbleState extends State<PantryChatBubble> {
  final _ctrl = TextEditingController();
  final _chat = PantryChat();
  final _msgs = <({bool me, String text})>[];
  bool _cloudBusy = false;
  int _reqToken = 0;

  Future<void> _send() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _msgs.add((me: true, text: q));
      _ctrl.clear();
    });

    // RAG local → top-K + near-expiry
    final top = _chat.pickTopK(widget.items, q, k: 20);
    final near = widget.advisor.getExpiringSoon(widget.items, withinDays: 3).map((e) => e.id).toList();
    final ctx = PantryChatContext.fromNow(
      items: top,
      nearExpiryIds: near,
      locationAllowed: false,  // à brancher selon les préférences globales
      locationApprox: null,
      temperatureC: null,
      userPrefs: const PantryUserPrefs(),
    );

    // hint local immédiat
    final hint = _chat.localHint(top, near);
    if (hint != null) setState(() => _msgs.add((me: false, text: hint)));

    setState(() => _cloudBusy = true);
    final myToken = ++_reqToken;

    Map<String, dynamic> json;
    try {
      json = await _chat.askCloud(q, ctx, timeout: const Duration(seconds: 6));
    } catch (_) {
      json = _chat.askCloudFallback(q, ctx);
    }
    if (!mounted || _reqToken != myToken) return;

    setState(() {
      _msgs.add((me: false, text: _chat.render(json)));
      _cloudBusy = false;
    });

    // Exécuter actions (ouvrir recettes, etc.)
    _chat.runActions(json, context);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _ctrl.text = widget.initialQuery!;
      // Optionnel : envoi automatique
      // WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      builder: (_, controller) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Text('Assistant garde-manger',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    if (_cloudBusy)
                      SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    IconButton(
                      tooltip: 'Fermer',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) {
                    final m = _msgs[i];
                    return Align(
                      alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: m.me
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(m.text),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          decoration: const InputDecoration(
                            hintText: 'Pose une question ou cherche un produit…',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Envoyer'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return GestureDetector(
      onTap: () {}, // laisse passer les gestures au sheet
      child: sheet,
    );
  }
}
