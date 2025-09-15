import 'package:flutter/material.dart';
import '../../models/pantry_item.dart';
import '../../services/ai/advisor_factory.dart';
import '../../services/chat/pantry_chat.dart';

class PantryChatScreen extends StatefulWidget {
  const PantryChatScreen({super.key});
  @override
  State<PantryChatScreen> createState() => _PantryChatScreenState();
}

class _PantryChatScreenState extends State<PantryChatScreen> {
  final _ctrl = TextEditingController();
  final _msgs = <({bool me, String text})>[];
  final _chat = PantryChat(); // stub HTTP
  final _advisor = getPantryAdvisor(preferCloud: false); // local pour RAG

  // TODO: injecte ta source réelle de produits (via InheritedWidget/provider)
  List<PantryItem> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupère la liste passée en arguments si dispo
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List<PantryItem>) _items = args;
  }

  Future<void> _send() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _msgs.add((me: true, text: q));
      _ctrl.clear();
    });

    // RAG local : top-K + nearExpiry
    final top = _chat.pickTopK(_items, q, k: 20);
    final near = _advisor.getExpiringSoon(_items, withinDays: 3).map((e) => e.id).toList();

    final ctx = PantryChatContext.fromNow(
      items: top,
      nearExpiryIds: near,
      // Ici, branche plus tard la localisation/météo selon les préférences utilisateur
      locationAllowed: false,
      locationApprox: null,
      temperatureC: null,
      userPrefs: const PantryUserPrefs(), // à remplir
    );

    final json = await _chat.askCloud(q, ctx); // HTTP → JSON
    final text = _chat.render(json);          // transforme JSON → message lisible

    if (!mounted) return;
    setState(() => _msgs.add((me: false, text: text)));
    _chat.runActions(json, context); // ex: ouvrir recette / ajouter aux courses
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant garde-manger')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
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
                        hintText: 'Pose une question (ex: "idées sans gluten ce soir ?")',
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
  }
}
