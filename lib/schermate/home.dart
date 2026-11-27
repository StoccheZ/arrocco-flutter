import 'package:material_ui/material_ui.dart';

import '../dati/lichess_api.dart';
import '../dati/modelli.dart';

/// Home: rating attuale per ogni cadenza giocata e variazione recente (RF2).
class SchermataHome extends StatefulWidget {
  const SchermataHome({
    super.key,
    required this.username,
    required this.api,
    required this.onScollega,
  });

  final String username;
  final LichessApi api;
  final VoidCallback onScollega;

  @override
  State<SchermataHome> createState() => _SchermataHomeState();
}

class _SchermataHomeState extends State<SchermataHome> {
  late Future<Utente> _utente;

  @override
  void initState() {
    super.initState();
    _utente = widget.api.getUtente(widget.username);
  }

  /// Riscarica il profilo; usato dal pulsante e dal trascinamento verso il basso.
  Future<void> _aggiorna() async {
    final nuovo = widget.api.getUtente(widget.username);
    setState(() => _utente = nuovo);
    try {
      await nuovo;
    } catch (_) {
      // L'errore viene mostrato dal FutureBuilder
    }
  }

  Future<void> _confermaScollega() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (contesto) => AlertDialog(
        title: const Text("Scollegare l'account?"),
        content: const Text('Lo storico dei puzzle resta salvato sul dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contesto, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contesto, true),
            child: const Text('Scollega'),
          ),
        ],
      ),
    );
    if (conferma == true) widget.onScollega();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Arrocco', style: Theme.of(context).textTheme.headlineSmall),
              ),
              IconButton(
                onPressed: _aggiorna,
                icon: const Icon(Icons.refresh),
                tooltip: 'Aggiorna rating',
              ),
              IconButton(
                onPressed: _confermaScollega,
                icon: const Icon(Icons.logout),
                tooltip: 'Scollega account',
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _aggiorna,
            child: FutureBuilder<Utente>(
              future: _utente,
              builder: (context, istantanea) {
                if (istantanea.hasData) return _ElencoRating(utente: istantanea.data!);
                if (istantanea.hasError) {
                  return _Errore(errore: istantanea.error!, onRiprova: _aggiorna);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ElencoRating extends StatelessWidget {
  const _ElencoRating({required this.utente});

  final Utente utente;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Ciao, ${utente.username}', style: tema.textTheme.titleLarge),
        const SizedBox(height: 16),
        if (utente.rating.isEmpty)
          const Text('Non hai ancora partite valutate su Lichess.')
        else
          for (final rating in utente.rating) _SchedaRating(rating: rating),
      ],
    );
  }
}

class _SchedaRating extends StatelessWidget {
  const _SchedaRating({required this.rating});

  final RatingCadenza rating;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final progresso = rating.progresso;
    final coloreProgresso = progresso > 0
        ? Colors.green.shade700
        : (progresso < 0 ? tema.colorScheme.error : tema.colorScheme.outline);
    final testoProgresso = progresso > 0 ? '+$progresso' : '$progresso';

    return Card(
      child: ListTile(
        title: Text(rating.etichetta, style: tema.textTheme.titleMedium),
        subtitle: Text('${rating.partite} ${rating.chiave == 'puzzle' ? 'puzzle' : 'partite'}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${rating.valore}${rating.provvisorio ? '?' : ''}',
              style: tema.textTheme.titleLarge,
            ),
            if (progresso != 0)
              Text(testoProgresso, style: TextStyle(color: coloreProgresso)),
          ],
        ),
      ),
    );
  }
}

class _Errore extends StatelessWidget {
  const _Errore({required this.errore, required this.onRiprova});

  final Object errore;
  final VoidCallback onRiprova;

  @override
  Widget build(BuildContext context) {
    final messaggio = errore is UtenteNonTrovato
        ? errore.toString()
        : 'Impossibile contattare Lichess. Controlla la connessione.';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Text(messaggio, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(onPressed: onRiprova, child: const Text('Riprova')),
        ),
      ],
    );
  }
}
